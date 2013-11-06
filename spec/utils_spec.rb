require 'spec_helper'

describe Overcommit::Utils do
  describe '.modified_files' do
    subject { Overcommit::Utils.modified_files }

    it 'does not include submodules' do
      submodule = repo do
        File.write 'foo', 'bar'
        `git add foo`
        `git commit -m "Initial commit"`
      end

      repo do
        `git submodule add #{submodule} test-sub`
        `git add .`
        expect(subject).to_not include('test-sub')
      end
    end

  end
end
