require 'spec_helper'

describe 'template directory' do
  let(:template_dir) { File.join(Overcommit::OVERCOMMIT_HOME, 'template-dir') }
  let(:hooks_dir) { File.join(template_dir, 'hooks') }

  it 'contains a hooks directory' do
    File.directory?(hooks_dir).should == true
  end

  describe 'the hooks directory' do
    it 'contains the master hook as an actual file with content' do
      master_hook = File.join(hooks_dir, 'overcommit-hook')
      File.exist?(master_hook).should == true
      File.size?(master_hook).should > 0
      File.symlink?(master_hook).should == false
    end

    it 'contains all other hooks as symlinks to the master hook' do
      Overcommit::Utils.supported_hook_types.each do |hook_type|
        File.symlink?(File.join(hooks_dir, hook_type)).should == true
      end
    end
  end
end
