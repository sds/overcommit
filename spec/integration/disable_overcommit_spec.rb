require 'spec_helper'

describe 'disabling Overcommit' do
  subject { shell(%w[git commit --allow-empty -m Test]) }

  around do |example|
    repo do
      `overcommit --install > #{File::NULL}`
      Overcommit::Utils.with_environment('OVERCOMMIT_DISABLE' => overcommit_disable) do
        touch 'blah'
        `git add blah`
        example.run
      end
    end
  end

  context 'when the OVERCOMMIT_DISABLE environment variable is set' do
    let(:overcommit_disable) { '1' }

    it 'exits successfully' do
      subject.status.should == 0
    end

    it 'does not run any hooks' do
      subject.stdout.should_not be_empty
      subject.stderr.should_not include 'Running pre-commit hooks'
    end
  end

  context 'when the OVERCOMMIT_DISABLE environment variable is set to zero' do
    let(:overcommit_disable) { '0' }

    it 'exits successfully' do
      subject.status.should == 0
    end

    it 'runs the hooks' do
      subject.stderr.should include 'Running pre-commit hooks'
    end
  end

  context 'when the OVERCOMMIT_DISABLE environment variable is unset' do
    let(:overcommit_disable) { nil }

    it 'exits successfully' do
      subject.status.should == 0
    end

    it 'runs the hooks' do
      subject.stderr.should include 'Running pre-commit hooks'
    end
  end
end
