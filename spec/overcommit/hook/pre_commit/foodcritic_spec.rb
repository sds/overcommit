require 'spec_helper'

describe Overcommit::Hook::PreCommit::Foodcritic do
  let(:config) do
    Overcommit::ConfigurationLoader.default_configuration.merge(
      Overcommit::Configuration.new('PreCommit' => {
                                      'Foodcritic' => {
                                        'cookbooks_directory' => '.',
                                        'environments_directory' => '.',
                                        'roles_directory' => '.'
                                      }
                                    })
    )
  end
  let(:context) { double('context') }
  let(:applicable_files) { %w[file1.rb file2.rb] }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(applicable_files)
    subject.stub(:modified).and_return(applicable_files)
  end

  around do |example|
    repo do
      example.run
    end
  end

  before do
    args = %w[-E -R -B].map { |arg| applicable_files.map { |file| [arg, file] } }.flatten
    subject.stub(:execute).with(%w[foodcritic -f any], args: args).and_return(result)
  end

  context 'and has 2 suggestions for metadata improvement' do
    let(:result) do
      double(
        success?: false,
        stdout: <<-EOF
FC008: Generated cookbook metadata needs updating: file1.rb:24
FC029: No leading cookbook name in recipe metadata: file2.rb:37
      EOF
      )
    end

    it { should warn }
  end

  context 'and has single suggestion for template' do
    let(:result) do
      double(
        success?: false,
        stdout: <<-EOF
FC034: Unused template variables: file1.rb:64
      EOF
      )
    end

    it { should warn }
  end

  context 'and does not have any suggestion' do
    let(:result) do
      double(success?: true, stdout: "\n")
    end

    it { should pass }
  end
end
