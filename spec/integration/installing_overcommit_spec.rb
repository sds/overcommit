require 'spec_helper'

describe 'installing Overcommit' do
  context 'when template directory points to the Overcommit template directory' do
    around do |example|
      repo(:template_dir => Overcommit::Installer::TEMPLATE_DIRECTORY) do
        example.run
      end
    end

    it 'automatically installs Overcommit hooks for new repositories' do
      Overcommit::Utils.supported_hook_types.each do |hook_type|
        hook_file = File.join('.git', 'hooks', hook_type)
        File.read(hook_file).should include 'OVERCOMMIT'
      end
    end

    context 'and Overcommit is manually installed' do
      before do
        `overcommit --install`
      end

      it 'replaces the hooks with symlinks' do
        Overcommit::Utils.supported_hook_types.each do |hook_type|
          hook_file = File.join('.git', 'hooks', hook_type)
          File.symlink?(hook_file).should == true
        end
      end
    end
  end
end
