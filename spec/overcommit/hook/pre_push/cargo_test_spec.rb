# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PrePush::CargoTest do
  let(:config) { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  context 'when all tests succeed' do
    before do
      result = double('result')
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when one test fails' do
    before do
      result = double('result')
      result.stub(:success?).and_return(false)
      result.stub(stdout: <<-ERRORMSG)
        running 2 tests
        test tests::foo ... ok
        test tests::bar ... FAILED

        failures:

        ---- tests::bar stdout ----
                thread 'tests::bar' panicked at 'assertion failed: `(left == right)`
          left: `None`,
         right: `Some(Bar)`', src/foobar.rs:88:9
        note: Run with `RUST_BACKTRACE=1` for a backtrace.


        failures:
          tests::bar

        test result: FAILED. 1 passed; 1 failed; 0 ignored; 0 measured; 0 filtered out
      ERRORMSG
      subject.stub(:execute).and_return(result)
    end

    it { should fail_hook }
  end
end
