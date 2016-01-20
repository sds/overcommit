require 'spec_helper'

describe Overcommit::Hook::PrePush::RSpec do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  context 'when rspec exits successfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when rspec exits unsuccessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'with a runtime error' do
      before do
        result.stub(stdout: '', stderr: <<-EOS)
          /home/user/.rbenv/gems/2.2.0/gems/rspec-core-3.2.2/lib/rspec/core/configuration.rb:1226:in `load': /home/user/dev/github/overcommit/spec/overcommit/hook/pre_push/rspec_spec.rb:49: can't find string "EOS" anywhere before EOF (SyntaxError)
          /home/user/dev/overcommit/spec/overcommit/hook/pre_push/rspec_spec.rb:29: syntax error, unexpected end-of-input
            from /home/user/.rbenv/gems/2.2.0/gems/rspec-core-3.2.2/lib/rspec/core/configuration.rb:1226:in `block in load_spec_files'
            from /home/user/.rbenv/gems/2.2.0/gems/rspec-core-3.2.2/lib/rspec/core/configuration.rb:1224:in `each'
            from /home/user/.rbenv/gems/2.2.0/gems/rspec-core-3.2.2/lib/rspec/core/configuration.rb:1224:in `load_spec_files'
            from /home/user/.rbenv/gems/2.2.0/gems/rspec-core-3.2.2/lib/rspec/core/runner.rb:97:in `setup'
            from /home/user/.rbenv/gems/2.2.0/gems/rspec-core-3.2.2/lib/rspec/core/runner.rb:85:in `run'
            from /home/user/.rbenv/gems/2.2.0/gems/rspec-core-3.2.2/lib/rspec/core/runner.rb:70:in `run'
            from /home/user/.rbenv/gems/2.2.0/gems/rspec-core-3.2.2/lib/rspec/core/runner.rb:38:in `invoke'
            from /home/user/.rbenv/versions/2.2.1/lib/ruby/gems/2.2.0/gems/rspec-core-3.2.2/exe/rspec:4:in `<top (required)>'
            from /home/user/.rbenv/versions/2.2.1/bin/rspec:23:in `load'
            from /home/user/.rbenv/versions/2.2.1/bin/rspec:23:in `<main>'
        EOS
      end

      it { should fail_hook }
    end

    context 'with a test failure' do
      before do
        result.stub(stderr: '', stdout: <<-EOS)
          .FF

          Failures:

            1) Overcommit::Hook::PrePush::RSpec when rspec exits unsuccessfully with a runtime error should fail
               Failure/Error: it { should fail_hook }
                 expected that the hook would fail
               # ./spec/overcommit/hook/pre_push/rspec_spec.rb:45:in `block (4 levels) in <top (required)>'

            2) Overcommit::Hook::PrePush::RSpec when rspec exits unsuccessfully with a test failure should fail
               Failure/Error: it { should fail_hook }
                 expected that the hook would fail
               # ./spec/overcommit/hook/pre_push/rspec_spec.rb:57:in `block (4 levels) in <top (required)>'

          Finished in 0.00505 seconds (files took 0.27437 seconds to load)
          3 examples, 2 failures

          Failed examples:

          rspec ./spec/overcommit/hook/pre_push/rspec_spec.rb:45 # Overcommit::Hook::PrePush::RSpec when rspec exits unsuccessfully with a runtime error should fail
          rspec ./spec/overcommit/hook/pre_push/rspec_spec.rb:57 # Overcommit::Hook::PrePush::RSpec when rspec exits unsuccessfully with a test failure should fail
        EOS
      end

      it { should fail_hook }
    end
  end
end
