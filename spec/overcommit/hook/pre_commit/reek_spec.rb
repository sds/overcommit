require 'spec_helper'

describe Overcommit::Hook::PreCommit::Reek do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.rb file2.rb])
  end

  context 'when reek exits successfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when reek exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports warnings' do
      context 'in old format' do
        before do
          result.stub(:stdout).and_return([
            'file1.rb -- 1 warning:',
            'file1.rb:1: MyClass#my_method performs a nil-check. (NilCheck)'
          ].join("\n"))
          result.stub(:stderr).and_return('')
        end

        it { should fail_hook }

        it 'parses the right file' do
          subject.run.map(&:file).should == ['file1.rb']
        end
      end

      context 'in new format' do
        before do
          result.stub(:stdout).and_return([
            'file1.rb -- 1 warning:',
            '  file1.rb:1: MyClass#my_method performs a nil-check. (NilCheck)'
          ].join("\n"))
          result.stub(:stderr).and_return('')
        end

        it { should fail_hook }

        it 'parses the right file' do
          subject.run.map(&:file).should == ['file1.rb']
        end
      end
    end
  end
end
