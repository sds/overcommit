require 'spec_helper'

describe Overcommit::Hook::PreCommit::CoffeeLint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.coffee file2.coffee])
  end

  context 'when coffeelint exits successfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    context 'with no warnings' do
      before do
        result.stub(:stdout).and_return(normalize_indent(<<-OUT))
          path,lineNumber,lineNumberEnd,level,message
        OUT
      end

      it { should pass }
    end

    context 'and it reports a warning' do
      before do
        result.stub(:stdout).and_return(normalize_indent(<<-OUT))
          path,lineNumber,lineNumberEnd,level,message
          file1.coffee,31,,warn,Comprehensions must have parentheses around them
        OUT
      end

      it { should warn }
    end
  end

  context 'when coffeelint exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports an error' do
      before do
        result.stub(:stdout).and_return(normalize_indent(<<-OUT))
          path,lineNumber,lineNumberEnd,level,message
          file1.coffee,17,,error,Duplicate key defined in object or class
        OUT
      end

      it { should fail_hook }
    end
  end
end
