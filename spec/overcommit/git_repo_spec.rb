require 'spec_helper'

describe Overcommit::GitRepo do
  describe '.staged_submodule_removals' do
    subject { described_class.staged_submodule_removals }

    around do |example|
      submodule = repo do
        `git commit --allow-empty -m "Submodule commit"`
      end

      repo do
        `git submodule add #{submodule} sub-repo 2>&1 > /dev/null`
        `git commit -m "Initial commit"`
        example.run
      end
    end

    context 'when there are no submodule removals staged' do
      it { should be_empty }
    end

    context 'when there are submodule additions staged' do
      before do
        another_submodule = repo do
          `git commit --allow-empty -m "Another submodule"`
        end

        `git submodule add #{another_submodule} another-sub-repo 2>&1 > /dev/null`
      end

      it { should be_empty }
    end

    context 'when there is one submodule removal staged' do
      before do
        `git rm sub-repo`
      end

      it 'returns the submodule that was removed' do
        subject.size.should == 1
        subject.first.tap do |sub|
          sub.path.should == 'sub-repo'
          File.directory?(sub.url).should == true
        end
      end
    end

    context 'when there are multiple submodule removals staged' do
      before do
        another_submodule = repo do
          `git commit --allow-empty -m "Another submodule"`
        end

        `git submodule add #{another_submodule} yet-another-sub-repo 2>&1 > /dev/null`
        `git commit -m "Add yet another submodule"`
        `git rm sub-repo`
        `git rm yet-another-sub-repo`
      end

      it 'returns all submodules that were removed' do
        subject.size.should == 2
        subject.map(&:path).sort.should == ['sub-repo', 'yet-another-sub-repo']
      end
    end
  end
end
