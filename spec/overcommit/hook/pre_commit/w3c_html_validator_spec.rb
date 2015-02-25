require 'spec_helper'
require 'w3c_validators'

describe Overcommit::Hook::PreCommit::W3cHtmlValidator do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.html file2.html])
  end

  context 'when w3c_validators exits with an exception' do
    let(:validator) { double('validator') }

    before do
      subject.stub(:validator).and_return(validator)
    end

    context 'when the validator is not available' do
      before do
        validator.stub(:validate_file).and_raise(W3CValidators::ValidatorUnavailable)
      end

      it { should fail_hook }
    end

    context 'when the validator response cannot be parsed' do
      before do
        validator.stub(:validate_file).and_raise(W3CValidators::ParsingError)
      end

      it { should fail_hook }
    end
  end

  context 'when w3c_validators exits without an exception' do
    let(:validator) { double('validator') }
    let(:results) { double('results') }
    let(:message) { double('message') }

    before do
      validator.stub(:validate_file).and_return(results)
      subject.stub(:validator).and_return(validator)
    end

    context 'with no errors or warnings' do
      before do
        results.stub(:errors => [], :warnings => [])
      end

      it { should pass }
    end

    context 'with a warning' do
      before do
        message.stub(:type => :warning, :line => '1', :message => '')
        results.stub(:errors => [], :warnings => [message])
        subject.stub(:modified_lines_in_file).and_return([2, 3])
      end

      it { should warn }
    end

    context 'with an error' do
      before do
        message.stub(:type => :error, :line => '1', :message => '')
        results.stub(:errors => [message], :warnings => [])
        subject.stub(:modified_lines_in_file).and_return([1, 2])
      end

      it { should fail_hook }
    end
  end
end
