require 'spec_helper'

describe Overcommit::Utils do
  describe '.script_path' do
    subject { described_class.script_path('some-script') }

    it 'points to the libexec scripts directory' do
      subject.should end_with File.join('libexec', 'scripts', 'some-script')
    end
  end

  describe '.repo_root' do
    let(:repo_dir) { repo }
    subject { described_class.repo_root }

    before do
      described_class.instance_variable_set(:@repo_root, nil)
    end

    around do |example|
      Dir.chdir(repo_dir) do
        example.run
      end
    end

    it 'returns the path to the repository root' do
      subject.should end_with repo_dir
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

    it { should =~ %w[commit-msg pre-commit post-checkout] }
  end

  describe '.supported_hook_type_classes' do
    subject { described_class.supported_hook_type_classes }

    it { should =~ %w[CommitMsg PreCommit PostCheckout] }
  end
end
