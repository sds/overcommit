# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::Foodcritic do
  let(:context) { double('context') }
  let(:result) { double(success?: true) }
  subject { described_class.new(config, context) }

  before do
    modified_files = applicable_files.map do |file|
      File.join(Overcommit::Utils.repo_root, file)
    end
    subject.stub(:applicable_files).and_return(modified_files)
    allow(subject).to receive(:execute).and_return(result)
  end

  around do |example|
    repo do
      example.run
    end
  end

  context 'when working in a single cookbook repository' do
    let(:config) { Overcommit::ConfigurationLoader.default_configuration }

    context 'and files have changed' do
      let(:applicable_files) do
        [
          'metadata.rb',
          File.join('recipes', 'default.rb'),
        ]
      end

      it 'passes the repository root as the cookbook path' do
        expect(subject).to receive(:execute).
          with(subject.command,
               hash_including(args: ['-B', Overcommit::Utils.repo_root]))
        subject.run
      end

      context 'and Foodcritic returns an unsuccessful exit status' do
        let(:result) do
          double(
            success?: false,
            stderr: '',
            stdout: <<-MSG,
            FC023: Prefer conditional attributes: recipes/default.rb:11
            FC065: Ensure source_url is set in metadata: metadata.rb:1
            MSG
          )
        end

        it { should warn }
      end

      context 'and Foodcritic returns a successful exit status' do
        it { should pass }
      end
    end
  end

  context 'when working in a repository with many cookbooks' do
    let(:config) do
      Overcommit::ConfigurationLoader.default_configuration.merge(
        Overcommit::Configuration.new(
          'PreCommit' => {
            'Foodcritic' => {
              'cookbooks_directory' => 'cookbooks',
              'environments_directory' => 'environments',
              'roles_directory' => 'roles',
            }
          }
        )
      )
    end

    context 'and multiple cookbooks, environments, and roles have changed' do
      let(:applicable_files) do
        [
          File.join('cookbooks', 'cookbook_a', 'metadata.rb'),
          File.join('cookbooks', 'cookbook_b', 'metadata.rb'),
          File.join('environments', 'production.json'),
          File.join('environments', 'staging.json'),
          File.join('roles', 'role_a.json'),
          File.join('roles', 'role_b.json'),
        ]
      end

      it 'passes the modified cookbook, environment, and role paths' do
        expect(subject).to receive(:execute).
          with(subject.command,
               hash_including(args: [
                 '-B', File.join(Overcommit::Utils.repo_root, 'cookbooks', 'cookbook_a'),
                 '-B', File.join(Overcommit::Utils.repo_root, 'cookbooks', 'cookbook_b'),
                 '-E', File.join(Overcommit::Utils.repo_root, 'environments', 'production.json'),
                 '-E', File.join(Overcommit::Utils.repo_root, 'environments', 'staging.json'),
                 '-R', File.join(Overcommit::Utils.repo_root, 'roles', 'role_a.json'),
                 '-R', File.join(Overcommit::Utils.repo_root, 'roles', 'role_b.json'),
               ]))
        subject.run
      end

      context 'and Foodcritic returns an unsuccessful exit status' do
        let(:result) do
          double(
            success?: false,
            stderr: '',
            stdout: <<-MSG,
            FC023: Prefer conditional attributes: cookbooks/cookbook_a/recipes/default.rb:11
            FC065: Ensure source_url is set in metadata: cookbooks/cookbook_b/metadata.rb:1
            MSG
          )
        end

        it { should warn }
      end

      context 'and Foodcritic returns a successful exit status' do
        let(:result) { double(success?: true) }

        it { should pass }
      end
    end
  end
end
