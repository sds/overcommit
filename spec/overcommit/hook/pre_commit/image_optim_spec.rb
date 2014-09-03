require 'spec_helper'
require 'image_optim'

describe Overcommit::Hook::PreCommit::ImageOptim do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.jpg file2.png])
  end

  context 'when a dependency of image_optim is not installed' do
    before do
      subject.stub(:optimize_images).and_raise(::ImageOptim::BinResolver::BinNotFound)
    end

    it { should fail_hook }
  end

  context 'when an image was optimized' do
    before do
      subject.stub(:optimize_images).and_return(['file1.jpg'])
    end

    it { should fail_hook }
  end

  context 'when no images were optimized' do
    before do
      subject.stub(:optimize_images).and_return([])
    end

    it { should pass }
  end
end
