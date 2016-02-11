require 'spec_helper'

describe Overcommit::Hook::PrePush::ProtectedBranches,
         if: Overcommit::GIT_VERSION >= '2.0' do
  let(:flags) { '' }
  let(:pushed_ref) { remote_ref }
  subject do
    shell("git push #{flags} origin #{pushed_ref}:#{remote_ref}".split)
  end

  let(:config) { <<-YML }
    CommitMsg:
      ALL:
        enabled: false
    PreCommit:
      ALL:
        enabled: false
    PrePush:
      ALL:
        enabled: false
      ProtectedBranches:
        enabled: true
        branches:
          - protected
  YML

  around do |example|
    remote_repo = repo do
      `git checkout -b protected > #{File::NULL} 2>&1`
      `git commit --allow-empty -m "Remote commit"`
      `git checkout -b unprotected > #{File::NULL} 2>&1`
      `git checkout -b dummy > #{File::NULL} 2>&1`
    end
    repo do
      File.open('.overcommit.yml', 'w') { |f| f.write(config) }
      `git remote add origin file://#{remote_repo}`
      `git checkout -b #{remote_ref} > #{File::NULL} 2>&1`
      `git commit --allow-empty -m "Local commit"`
      example.run
    end
  end

  shared_context 'deleting' do
    let(:pushed_ref) { '' }
  end

  shared_context 'force-pushing' do
    let(:flags) { '--force' }
  end

  shared_context 'remote exists locally' do
    before { `git fetch origin #{remote_ref} > #{File::NULL} 2>&1` }
  end

  shared_context 'local branch up-to-date' do
    before { `git rebase --keep-empty origin/#{remote_ref} > #{File::NULL} 2>&1` }
  end

  shared_context 'ProtectedBranches enabled' do
    before { `overcommit --install > #{File::NULL}` }
  end

  shared_examples 'push succeeds' do
    it 'exits successfully' do
      subject.status.should == 0
    end
  end

  shared_examples 'push fails' do
    it 'exits with a non-zero status' do
      subject.status.should_not == 0
    end
  end

  shared_examples 'push succeeds when remote exists locally' do
    context 'when remote exists locally' do
      include_context 'remote exists locally'

      context 'when up-to-date with remote' do
        include_context 'local branch up-to-date'
        include_examples 'push succeeds'
      end

      context 'when not up-to-date with remote' do
        include_examples 'push succeeds'
      end
    end

    context 'when remote does not exist locally' do
      include_examples 'push fails'
    end
  end

  shared_examples 'push succeeds when up-to-date with remote' do
    context 'when remote exists locally' do
      include_context 'remote exists locally'

      context 'when up-to-date with remote' do
        include_context 'local branch up-to-date'
        include_examples 'push succeeds'
      end

      context 'when not up-to-date with remote' do
        include_examples 'push fails'
      end
    end

    context 'when remote does not exist locally' do
      include_examples 'push fails'
    end
  end

  shared_examples 'push always fails' do
    context 'when remote exists locally' do
      include_context 'remote exists locally'

      context 'when up-to-date with remote' do
        include_context 'local branch up-to-date'
        include_examples 'push fails'
      end

      context 'when not up-to-date with remote' do
        include_examples 'push fails'
      end
    end

    context 'when remote does not exist locally' do
      include_examples 'push fails'
    end
  end

  shared_examples 'push always succeeds' do
    context 'when remote exists locally' do
      include_context 'remote exists locally'

      context 'when up-to-date with remote' do
        include_context 'local branch up-to-date'
        include_examples 'push succeeds'
      end

      context 'when not up-to-date with remote' do
        include_examples 'push succeeds'
      end
    end

    context 'when remote does not exist locally' do
      include_examples 'push succeeds'
    end
  end

  context 'when pushing to a protected branch' do
    let(:remote_ref) { 'protected' }

    context 'when force-pushing' do
      include_context 'force-pushing'

      context 'with ProtectedBranches enabled' do
        include_context 'ProtectedBranches enabled'
        include_examples 'push succeeds when up-to-date with remote'
      end

      context 'with ProtectedBranches disabled' do
        include_examples 'push always succeeds'
      end
    end

    context 'when deleting' do
      include_context 'deleting'

      context 'with ProtectedBranches enabled' do
        include_context 'ProtectedBranches enabled'
        include_examples 'push always fails'
      end

      context 'with ProtectedBranches disabled' do
        include_examples 'push always succeeds'
      end
    end

    context 'when not deleting or force-pushing' do
      context 'with ProtectedBranches enabled' do
        include_context 'ProtectedBranches enabled'
        include_examples 'push succeeds when up-to-date with remote'
      end

      context 'with ProtectedBranches disabled' do
        include_examples 'push succeeds when up-to-date with remote'
      end
    end
  end

  context 'when pushing to an unprotected branch' do
    let(:remote_ref) { 'unprotected' }

    context 'when force-pushing' do
      include_context 'force-pushing'

      context 'with ProtectedBranches enabled' do
        include_context 'ProtectedBranches enabled'
        include_examples 'push always succeeds'
      end

      context 'with ProtectedBranches disabled' do
        include_examples 'push always succeeds'
      end
    end

    context 'when deleting' do
      include_context 'deleting'

      context 'with ProtectedBranches enabled' do
        include_context 'ProtectedBranches enabled'
        include_examples 'push always succeeds'
      end

      context 'with ProtectedBranches disabled' do
        include_examples 'push always succeeds'
      end
    end

    context 'when not deleting or force-pushing' do
      context 'with ProtectedBranches enabled' do
        include_context 'ProtectedBranches enabled'
        include_examples 'push succeeds when up-to-date with remote'
      end

      context 'with ProtectedBranches disabled' do
        include_examples 'push succeeds when up-to-date with remote'
      end
    end
  end

  context 'when pushing to a nonexistent branch' do
    let(:remote_ref) { 'new-branch' }

    context 'when force-pushing' do
      include_context 'force-pushing'

      context 'with ProtectedBranches enabled' do
        include_context 'ProtectedBranches enabled'
        include_examples 'push succeeds'
      end

      context 'with ProtectedBranches disabled' do
        include_examples 'push succeeds'
      end
    end

    context 'when deleting' do
      include_context 'deleting'

      context 'with ProtectedBranches enabled' do
        include_context 'ProtectedBranches enabled'
        include_examples 'push fails'
      end

      context 'with ProtectedBranches disabled' do
        include_examples 'push fails'
      end
    end

    context 'when not deleting or force-pushing' do
      context 'with ProtectedBranches enabled' do
        include_context 'ProtectedBranches enabled'
        include_examples 'push succeeds'
      end

      context 'with ProtectedBranches disabled' do
        include_examples 'push succeeds'
      end
    end
  end
end
