require 'spec_helper'

describe Overcommit::Hook::PreCommit::Flay do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  let(:applicable_files) { %w[file1.rb] }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(applicable_files)
  end

  around do |example|
    repo do
      example.run
    end
  end

  before do
    command = %w[flay --mass 16 --fuzzy 1]
    subject.stub(:execute).with(command, args: applicable_files).and_return(result)
  end

  context 'flay discovered two issues' do
    let(:result) do
      double(
        success?: false,
        stdout: <<-MSG
Total score (lower is better) = 268

1) IDENTICAL code found in :defn (mass*2 = 148)
  app/whatever11.rb:105
  app/whatever12.rb:76

2) Similar code found in :defn (mass = 120)
  app/whatever21.rb:105
  app/whatever22.rb:76

MSG
      )
    end

    it { should fail_hook }
  end

  context 'flay discovered no issues' do
    let(:result) do
      double(
        success?: false,
        stdout: <<-MSG
Total score (lower is better) = 0
MSG
      )
    end

    it { should pass }
  end

end
