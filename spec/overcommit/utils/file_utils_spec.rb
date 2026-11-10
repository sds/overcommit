# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Utils::FileUtils do
  around do |example|
    directory { example.run }
  end

  shared_examples 'a symbolic link' do
    before do
      described_class.symlink(target, 'some link')
    end

    it 'is recognized as a symlink' do
      described_class.symlink?('some link').should == true
    end

    it 'preserves the target path' do
      described_class.readlink('some link').tr('\\', '/').should == target
    end
  end

  context 'with a file target containing spaces' do
    let(:target) { 'some file' }

    before { echo('contents', target) }

    it_behaves_like 'a symbolic link'
  end

  context 'with a directory target containing spaces' do
    let(:target) { 'some directory' }

    before { FileUtils.mkdir(target) }

    it_behaves_like 'a symbolic link'
  end

  context 'with a missing target' do
    let(:target) { 'missing file' }

    it_behaves_like 'a symbolic link'
  end

  it 'does not recognize a regular file as a symlink' do
    touch 'regular file'
    described_class.symlink?('regular file').should == false
  end

  it 'does not recognize a regular directory as a symlink' do
    FileUtils.mkdir('regular directory')
    described_class.symlink?('regular directory').should == false
  end

  it 'does not recognize a nonexistent path as a symlink' do
    described_class.symlink?('missing file').should == false
  end

  it 'raises when a symlink cannot be created' do
    touch 'existing file'
    expect { described_class.symlink('target', 'existing file') }.to raise_error(Errno::EEXIST)
  end
end
