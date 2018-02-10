require 'spec_helper'

describe Overcommit::Hook::PreCommit::YarnCheck do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  context 'when yarn.lock is ignored' do
    around do |example|
      repo do
        touch 'yarn.lock'
        echo('yarn.lock', '.gitignore')
        `git add .gitignore`
        `git commit -m "Ignore yarn.lock"`
        example.run
      end
    end

    it { should pass }
  end

  context 'when yarn.lock is not ignored' do
    let(:result) { double('result') }

    around do |example|
      repo do
        example.run
      end
    end

    before do
      result.stub(stderr: stderr)
      subject.stub(:execute).with(%w[git ls-files -o -i --exclude-standard]).
        and_return(double(stdout: ''))
      subject.stub(:execute).with(%w[yarn check --silent --no-progress --non-interactive]).
        and_return(result)
    end

    context 'and yarn check reports no errors' do
      let(:stderr) { '' }

      it { should pass }

      context 'and there was a change to the yarn.lock' do
        before do
          subject.stub(:execute).with(%w[yarn check --silent --no-progress --non-interactive]) do
            echo('stuff', 'yarn.lock')
            double(stderr: '')
          end
        end

        it { should fail_hook }
      end
    end

    context 'and yarn check contains only warnings' do
      let(:stderr) do
        <<STDERR
warning "parent-package#child-package@version" could be deduped from "one version" to "another version"
STDERR
      end

      it { should pass }
    end

    context 'and yarn check contains unactionable errors' do
      let(:stderr) do
        <<STDERR
error "peer-dependency#peer@a || list || of || versions" doesn't satisfy found match of "peer@different-version"
error "bad-maintainer#bad-package" is wrong version: expected "something normal", got "something crazy"
STDERR
      end

      it { should pass }
    end

    context 'and yarn check contains actionable errors' do
      let(:stderr) do
        <<STDERR
error Lockfile does not contain pattern: "thing-i-updated-in-package.json@new-version"
STDERR
      end

      it { should fail_hook }
    end
  end
end
