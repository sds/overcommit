# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'open3'
require 'tmpdir'

describe 'template directory' do
  let(:template_dir) { File.join(Overcommit::HOME, 'template-dir') }
  let(:hooks_dir) { File.join(template_dir, 'hooks') }

  it 'contains a hooks directory' do
    File.directory?(hooks_dir).should == true
  end

  describe 'the hooks directory' do
    it 'contains the master hook as an actual file with content' do
      master_hook = File.join(hooks_dir, 'overcommit-hook')
      File.exist?(master_hook).should == true
      File.size?(master_hook).should > 0
      Overcommit::Utils::FileUtils.symlink?(master_hook).should == false
    end

    it 'contains all other hooks as copies of the master hook' do
      Overcommit::Utils.supported_hook_types.each do |hook_type|
        FileUtils.compare_file(File.join(hooks_dir, hook_type),
                               File.join(hooks_dir, 'overcommit-hook')).should == true
      end
    end

    it 'reads a non-ASCII .overcommit.yml when the default external encoding is ASCII' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, '.overcommit.yml'), "# caf\u00e9\ngemfile: false\n",
                   encoding: 'UTF-8')

        _stdout, stderr, _status = Open3.capture3(
          { 'LC_ALL' => 'C', 'LANG' => 'C' },
          RbConfig.ruby, '-I', File.join(Overcommit::HOME, 'lib'),
          File.join(hooks_dir, 'pre-commit'),
          chdir: dir, stdin_data: ''
        )

        stderr.should_not include('invalid byte sequence')
      end
    end

    it 'contains no symlinks' do
      Overcommit::Utils.supported_hook_types.each do |hook_type|
        Overcommit::Utils::FileUtils.symlink?(File.join(hooks_dir, hook_type)).should == false
      end
    end
  end
end
