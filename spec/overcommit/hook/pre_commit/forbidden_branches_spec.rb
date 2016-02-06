require 'spec_helper'

describe Overcommit::Hook::PreCommit::ForbiddenBranches do
  let(:default_config) { Overcommit::ConfigurationLoader.default_configuration }
  let(:branch_patterns) { ['master', 'release/*'] }
  let(:config) do
    default_config.merge(Overcommit::Configuration.new(
      'PreCommit' => {
        'ForbiddenBranches' => {
          'branch_patterns' => branch_patterns
        }
      }))
  end
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  around do |example|
    repo do
      `git checkout -b #{current_branch} > #{File::NULL} 2>&1`
      example.run
    end
  end

  context 'when committing to a permitted branch' do
    let(:current_branch) { 'permitted' }
    it { should pass }
  end

  context 'when committing to a forbidden branch' do
    context 'when branch name matches a forbidden branch exactly' do
      let(:current_branch) { 'master' }
      it { should fail_hook }
    end

    context 'when branch name matches a forbidden branch glob pattern' do
      let(:current_branch) { 'release/1.0' }
      it { should fail_hook }
    end
  end
end
