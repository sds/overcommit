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
        result.stub(:stdout).and_return('{
          "file1.coffee": []
        }')
      end

      it { should pass }
    end

    context 'and it reports a warning' do
      before do
        result.stub(:stdout).and_return('{
          "file1.coffee": [
            {
              "name": "ensure_comprehensions",
              "level": "warn",
              "message": "Comprehensions must have parentheses around them",
              "description": "This rule makes sure that parentheses are around comprehensions.",
              "context": "",
              "lineNumber": 31,
              "line": "cubes = math.cube num for num in list",
              "rule": "ensure_comprehensions"
            }
          ]
        }')
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
        result.stub(:stdout).and_return('{
          "file1.coffee": [
            {
              "name": "duplicate_key",
              "level": "error",
              "message": "Duplicate key defined in object or class",
              "description": "Prevents defining duplicate keys in object literals and classes",
              "lineNumber": 17,
              "line": "  root: foo",
              "rule": "duplicate_key"
            }
          ]
        }')
      end

      it { should fail_hook }
    end

    context 'and its output is not valid JSON' do
      before do
        result.stub(:stdout).and_return('foo')
      end

      it { should fail_hook }
    end
  end
end
