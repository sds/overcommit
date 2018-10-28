# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::ImageOptim do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.jpg file2.png])
  end

  context 'when image_optim exits successfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    context 'and images were optimized' do
      before do
        result.stub(:stdout).and_return([
          '32.30%   1.2K  file1.jpg',
          'Total: 32.30%   1.2K',
        ].join("\n"))
      end

      it { should fail_hook }
    end

    context 'and no images were optimized' do
      before do
        result.stub(:stdout).and_return([
          '------         app/assets/images/favicons/favicon-96x96.png',
          'Total: ------',
        ].join("\n"))
      end

      it { should pass }
    end
  end

  context 'when image_optim exits unsuccessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      result.stub(:stdout).and_return('An error occurred')
      result.stub(:stderr).and_return('')
      subject.stub(:execute).and_return(result)
    end

    it { should fail_hook }
  end
end
