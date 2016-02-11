require 'spec_helper'

describe Overcommit::Hook::PrePush::Minitest do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context', all_files: ['test/test_foo.rb']) }
  subject { described_class.new(config, context) }

  context 'when minitest exits successfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when minitest exits unsuccessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'with a runtime error' do
      before do
        result.stub(stdout: '', stderr: <<-EOS)
          1) Error:
          FooTest#test_: foo should bar. :
          RuntimeError:
          test/model/foo_test.rb:1:in `block (2 levels) in <class:FooTest>'
        EOS
      end

      it { should fail_hook }
    end
  end
end
