# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PrePush::PubTest do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  context 'when pub test exits successfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when pub test exits unsuccessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'with a runtime error' do
      before do
        result.stub(stdout: '', stderr: <<-MSG)
          00:01 +0 -1: test/test_test.dart: String.split() splits the string on the delimiter [E]
            Exception
            test/test_test.dart 6:5  main.<fn>

          00:01 +1 -1: Some tests failed.
        MSG
      end

      it { should fail_hook }
    end

    context 'with a test failure' do
      before do
        result.stub(stderr: '', stdout: <<-MSG)
          00:01 +0 -1: test/test_test.dart: String.split() splits the string on the delimiter [E]
            Expected: ['fooo', 'bar', 'baz']
              Actual: ['foo', 'bar', 'baz']
               Which: at location [0] is 'foo' instead of 'fooo'

            package:test_api         expect
            test/test_test.dart 6:5  main.<fn>

          00:01 +1 -1: Some tests failed.
        MSG
      end

      it { should fail_hook }
    end
  end
end
