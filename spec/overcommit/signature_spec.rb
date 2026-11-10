# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Signature do
  let(:key) { 'overcommit.configuration.signature' }
  let(:signature) { Digest::SHA256.hexdigest('original configuration') }
  let(:other_signature) { Digest::SHA256.hexdigest('changed configuration') }
  let(:store) { described_class.new(key) }
  let(:root) { File.join(Overcommit::Utils.git_dir, 'overcommit-signatures') }
  let(:signature_file) { File.join(root, Digest::SHA256.hexdigest(key), signature) }

  around do |example|
    repo { example.run }
  end

  it 'does not approve a signature that was never signed' do
    store.include?(signature).should == false
    store.recorded?.should == false
    File.exist?(root).should == false
  end

  it 'remembers all approvals across instances without growing Git config' do
    store.add(signature)
    store.add(other_signature)
    restored = described_class.new(key)
    restored.include?(signature).should == true
    restored.include?(other_signature).should == true
    restored.recorded?.should == true
    shell(%W[git config --local --get #{key}]).status.should == 1
  end

  it 'signs the same content idempotently' do
    2.times { store.add(signature) }
    Dir[File.join(root, '*', '*')].size.should == 1
    store.include?(signature).should == true
  end

  it 'indexes approvals independently of the number of historical signatures' do
    1000.times { |i| store.add(Digest::SHA256.hexdigest(i.to_s)) }
    store.add(signature)
    File.should_receive(:read).once.with(signature_file).and_call_original
    Dir.should_not_receive(:glob)
    store.include?(signature).should == true
  end

  it 'keeps approvals separate for each hook and hook type' do
    store.add(signature)
    %w[overcommit.PreCommit.Custom.signature
       overcommit.PostCheckout.Custom.signature].each do |name|
      described_class.new(name).include?(signature).should == false
    end
  end

  it 'does not derive filesystem paths from hook names' do
    described_class.new('overcommit.PreCommit.../../Custom.signature').add(signature)
    Dir[File.join(root, '*', '*')].size.should == 1
  end

  it 'revokes one approval by removing its file while preserving others' do
    store.add(signature)
    store.add(other_signature)
    File.delete(signature_file)
    restored = described_class.new(key)
    restored.include?(signature).should == false
    restored.include?(other_signature).should == true
  end

  it 'revokes all approvals by removing the history directory' do
    store.add(signature)
    FileUtils.rm_rf(root)
    restored = described_class.new(key)
    restored.include?(signature).should == false
    restored.recorded?.should == false
  end

  it 'rejects a corrupted or truncated approval file' do
    store.add(signature)
    File.write(signature_file, '')
    store.include?(signature).should == false
  end

  it 'rejects an approval file copied from another hook' do
    store.add(signature)
    File.write(signature_file, "overcommit.PreCommit.Custom.signature\n#{signature}\n")
    store.include?(signature).should == false
  end

  it 'does not lose approvals when Git garbage collects unreachable objects' do
    store.add(signature)
    shell(%w[git gc --prune=now]).status.should == 0
    described_class.new(key).include?(signature).should == true
  end

  it 'does not trust signature blobs received through a remote tag' do
    # Reproduce the original implementation's trust-injection vulnerability.
    store.add(signature)
    File.write('untrusted-configuration', 'changed configuration')
    config_id = shell(%w[git hash-object untrusted-configuration]).stdout.chomp
    # The old implementation would accept this blob's presence as approval.
    File.write('injected-signature', "#{config_id} #{other_signature}")
    object_id = shell(%w[git hash-object -w injected-signature]).stdout.chomp
    shell(%W[git update-ref refs/tags/forged-approval #{object_id}]).status.should == 0
    destination = File.join(File.dirname(Dir.pwd), 'clone')
    shell(['git', 'clone', '--no-local', Dir.pwd, destination]).status.should == 0
    Dir.chdir(destination) do
      %w[git_dir repo_root].each { |name| Overcommit::Utils.instance_variable_set("@#{name}", nil) }
      shell(%W[git cat-file -e #{object_id}]).status.should == 0
      cloned = described_class.new(key)
      cloned.include?(signature).should == false
      cloned.include?(other_signature).should == false
    end
  end

  context 'with a legacy approval in Git config' do
    before do
      shell(%W[git config --local #{key} #{signature}]).status.should == 0
    end

    it 'migrates the old approval and removes the old key' do
      store.include?(signature).should == true
      shell(%W[git config --local --get #{key}]).status.should == 1
      store.include?(other_signature).should == false
    end

    it 'preserves the old approval when signing a new configuration first' do
      store.add(other_signature)
      store.include?(signature).should == true
      store.include?(other_signature).should == true
    end

    it 'does not resurrect a revoked legacy approval' do
      store.include?(signature).should == true
      FileUtils.rm_rf(root)
      described_class.new(key).include?(signature).should == false
    end

    it 'leaves the legacy approval intact if writing history fails' do
      FileUtils.should_receive(:mkdir_p).and_raise(Errno::EACCES)
      expect do
        store
      end.to raise_error(Overcommit::Exceptions::SignatureError, /write signature history/)
      shell(%W[git config --local --get #{key}]).stdout.chomp.should == signature
    end

    it 'does not accept an invalid legacy digest as a path' do
      shell(%W[git config --local #{key} ../../untrusted]).status.should == 0
      store.include?(signature).should == false
      File.exist?(root).should == false
    end
  end

  context 'with worktree configuration enabled' do
    before { shell(%w[git config --local extensions.worktreeConfig true]) }

    it 'migrates only the approval in worktree config' do
      shell(%W[git config --local #{key} #{other_signature}]).status.should == 0
      shell(%W[git config --worktree #{key} #{signature}]).status.should == 0
      store.include?(signature).should == true
      store.include?(other_signature).should == false
      shell(%W[git config --worktree --get #{key}]).status.should == 1
      shell(%W[git config --local --get #{key}]).stdout.chomp.should == other_signature
    end
  end

  it 'supports repositories whose Git directory is stored separately' do
    destination = File.join(File.dirname(Dir.pwd), 'repository metadata')
    shell(['git', 'init', '--separate-git-dir', destination]).status.should == 0
    Overcommit::Utils.instance_variable_set(:@git_dir, nil)
    store.add(signature)
    File.file?('.git').should == true
    Dir[File.join(destination, 'overcommit-signatures', '*', '*')].size.should == 1
    described_class.new(key).include?(signature).should == true
  end

  it 'handles concurrent approval writes without forgetting any signatures' do
    # Separate instances have no shared Ruby state, as with concurrent hook runs.
    stores = Array.new(4) { described_class.new(key) }
    signatures = Array.new(40) { |i| Digest::SHA256.hexdigest(i.to_s) }
    threads = stores.each_with_index.map do |history, index|
      Thread.new { signatures.rotate(index * 10).each { |sig| history.add(sig) } }
    end
    threads.each(&:value)
    restored = described_class.new(key)
    signatures.each { |sig| restored.include?(sig).should == true }
  end

  it 'fails closed if reading an approval fails' do
    store.add(signature)
    File.should_receive(:read).with(signature_file).and_raise(Errno::EACCES)
    expect { store.include?(signature) }.
      to raise_error(Overcommit::Exceptions::SignatureError, /read signature history/)
  end

  it 'reports Git config read errors' do
    Overcommit::Utils.stub(:execute).and_call_original
    result = double(status: 2, success?: false, stderr: 'cannot read config')
    Overcommit::Utils.should_receive(:execute).
      with(%W[git config --local --get #{key}]).and_return(result)
    expect { store }.to raise_error(Overcommit::Exceptions::GitConfigError, /cannot read config/)
  end

  it 'reports Git config removal errors without losing the migrated approval' do
    shell(%W[git config --local #{key} #{signature}]).status.should == 0
    Overcommit::Utils.stub(:execute).and_call_original
    result = double(status: 2, success?: false, stderr: 'cannot lock config')
    Overcommit::Utils.should_receive(:execute).
      with(%W[git config --local --unset-all #{key}]).and_return(result)
    expect { store }.to raise_error(Overcommit::Exceptions::GitConfigError, /cannot lock config/)
    File.read(signature_file).should include(signature)
  end
end
