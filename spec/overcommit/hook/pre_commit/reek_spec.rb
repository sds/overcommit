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

    context 'and it reports lines that were not modified by the commit' do
      before do
        result.stub(:stdout).and_return([
          'file1.rb -- 1 warning:',
          'file1.rb:1: MyClass#my_method performs a nil-check. (NilCheck)'
        ].join("\n"))
        result.stub(:stderr).and_return('')

        subject.stub(:modified_lines).and_return([2, 3])
      end

      expected_message = "Modified files have lints (on lines you didn't modify)\n" \
        'file1.rb:1: MyClass#my_method performs a nil-check. (NilCheck)'

      it { should warn expected_message }
    end

    context 'and it reports lines that were modified by the commit' do
      before do
        result.stub(:stdout).and_return([
          'file1.rb -- 2 warnings:',
          'file1.rb:1: MyClass#my_method1 performs a nil-check. (NilCheck)',
          'file1.rb:3: MyClass#my_method3 performs a nil-check. (NilCheck)'
        ].join("\n"))
        result.stub(:stderr).and_return('')

        subject.stub(:modified_lines).and_return([1, 2])
      end

      expected_message = 'file1.rb:1: MyClass#my_method1 performs a nil-check. (NilCheck)'

      it { should fail_hook expected_message }
    end
  end
end
