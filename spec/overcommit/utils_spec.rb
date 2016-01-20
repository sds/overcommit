require 'spec_helper'
require 'securerandom'

describe Overcommit::Utils do
  describe '.script_path' do
    subject { described_class.script_path('some-script') }

    it 'points to the libexec scripts directory' do
      subject.should end_with File.join('libexec', 'some-script')
    end
  end

  describe '.repo_root' do
    let(:repo_dir) { repo }
    subject { described_class.repo_root }

    around do |example|
      Dir.chdir(repo_dir) do
        example.run
      end
    end

    it 'returns the path to the repository root' do
      # realpath is so spec passes on Mac OS X
      subject.should == File.realpath(repo_dir)
    end

    context 'when there is no .git directory' do
      before do
        FileUtils.rm_rf('.git', secure: true)
      end

      it 'raises an exception' do
        expect { subject }.to raise_error Overcommit::Exceptions::InvalidGitRepo
      end
    end
  end

  describe '.git_dir' do
    let(:repo_dir) { repo }
    subject { described_class.git_dir }

    around do |example|
      Dir.chdir(repo_dir) do
        example.run
      end
    end

    context 'when .git is a directory' do
      it 'returns the path to the directory' do
        subject.should end_with File.join(repo_dir, '.git')
      end
    end

    context 'when .git is a file' do
      before do
        FileUtils.rm_rf('.git', secure: true)
        echo("gitdir: #{git_dir_path}", '.git')
      end

      context 'and is a relative path' do
        let(:git_dir_path) { '../.git' }

        it 'returns the path contained in the file' do
          # realpath is so spec passes on Mac OS X
          subject.should == File.join(File.realpath(File.dirname(repo_dir)), '.git')
        end
      end

      context 'and is an absolute path' do
        let(:git_dir_path) { '/some/arbitrary/path/.git' }

        it 'returns the path contained in the file' do
          subject.should == git_dir_path
        end
      end
    end
  end

  describe '.strip_color_codes' do
    subject { described_class.strip_color_codes(text) }

    context 'with an empty string' do
      let(:text) { '' }

      it { should == '' }
    end

    context 'with a string with no escape sequences' do
      let(:text) { 'A normal string' }

      it { should == text }
    end

    context 'with a string with escape sequences' do
      let(:text) { "A \e[31mcolored string\e[39m" }

      it { should == 'A colored string' }
    end
  end

  describe '.snake_case' do
    it 'converts camel case to underscores' do
      described_class.snake_case('HelloWorld').should == 'hello_world'
    end

    it 'leaves underscored strings as is' do
      described_class.snake_case('hello_world').should == 'hello_world'
    end

    it 'converts namespaced class names to paths' do
      described_class.snake_case('SomeModule::SomeOtherModule::SomeClass').
        should == 'some_module/some_other_module/some_class'
    end
  end

  describe '.camel_case' do
    it 'converts underscored strings to camel case' do
      described_class.camel_case('hello_world').should == 'HelloWorld'
    end

    it 'leaves already camel-cased strings as is' do
      described_class.camel_case('HelloWorld').should == 'HelloWorld'
    end

    it 'converts hyphenated strings to camel case' do
      described_class.camel_case('hello-world').should == 'HelloWorld'
    end
  end

  describe '.supported_hook_types' do
    subject { described_class.supported_hook_types }

    # rubocop:disable Metrics/LineLength
    it { should =~ %w[commit-msg pre-commit post-checkout post-commit post-merge post-rewrite pre-push pre-rebase] }
    # rubocop:enable Metrics/LineLength
  end

  describe '.supported_hook_type_classes' do
    subject { described_class.supported_hook_type_classes }

    # rubocop:disable Metrics/LineLength
    it { should =~ %w[CommitMsg PreCommit PostCheckout PostCommit PostMerge PostRewrite PrePush PreRebase] }
    # rubocop:enable Metrics/LineLength
  end

  describe '.parent_command' do
    subject { described_class.parent_command }

    before do
      Process.stub(:ppid) { Process.pid }
    end

    it { should =~ /rspec/ }
  end

  describe '.execute' do
    let(:arguments) { %w[echo Hello World] }
    subject { described_class.execute(arguments) }

    it 'returns result with the output' do
      subject.stdout.should == "Hello World\n"
    end

    it 'returns result with the exit status' do
      subject.status.should == 0
    end

    context 'when one of the arguments is a lone pipe character' do
      let(:arguments) { %w[ps aux | grep bash] }

      it 'raises an exception' do
        expect { subject }.to raise_error Overcommit::Exceptions::InvalidCommandArgs
      end
    end

    context 'when given an input stream' do
      let(:arguments) { ['cat', '-'] }
      let(:input) { 'Hello world' }

      subject { described_class.execute(arguments, input: input) }

      it 'passes the input to the standard input stream' do
        subject.stdout.should == "Hello world\n"
      end
    end

    context 'when given a list of arguments to execute in chunks' do
      let(:arguments) { ['echo'] }
      let(:splittable_args) { %w[1 2 3] }

      subject { described_class.execute(arguments, args: splittable_args) }

      it 'invokes CommandSplitter.execute' do
        Overcommit::CommandSplitter.
          should_receive(:execute).
          with(arguments, args: splittable_args).
          and_return(double(status: 0, stdout: '', stderr: ''))
        subject
      end

      it 'returns a result' do
        subject.should be_success
        subject.stdout.should == "1 2 3\n"
        subject.stderr.should == ''
      end
    end
  end

  describe '.execute_in_background' do
    let(:arguments) { %w[touch some-file] }

    subject { described_class.execute_in_background(arguments) }

    around do |example|
      directory do
        example.run
      end
    end

    it 'executes the command' do
      wait_until { subject.exited? } # Make sure process terminated before checking
      File.exist?('some-file').should == true
    end
  end

  describe '.with_environment' do
    let(:var_name) { "OVERCOMMIT_TEST_VAR_#{SecureRandom.hex}" }

    shared_examples_for 'with_environment' do
      it 'sets the value of the variable within the block' do
        described_class.with_environment var_name => 'modified_value' do
          ENV[var_name].should == 'modified_value'
        end
      end
    end

    context 'when setting an environment variable that was not already set' do
      it_should_behave_like 'with_environment'

      it 'deletes the value once the block has exited' do
        described_class.with_environment var_name => 'modified_value' do
          # Do something...
        end

        ENV[var_name].should be_nil
      end
    end

    context 'when setting an environment variable that was already set' do
      around do |example|
        ENV[var_name] = 'previous_value'
        example.run
        ENV.delete(var_name)
      end

      it_should_behave_like 'with_environment'

      it 'restores the old value once the block has exited' do
        described_class.with_environment var_name => 'modified_value' do
          # Do something...
        end

        ENV[var_name].should == 'previous_value'
      end
    end
  end
end
