require 'spec_helper'

describe Overcommit::Hook::PreCommit::LicenceHeader do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  context 'when licence file is missing' do
    before do
      subject.stub(:licence_lines).and_raise(Errno::ENOENT)
    end

    it { should fail_hook }
  end

  context 'with headers in all applicable files' do
    let(:licence) do
      ['Hello World', 'Copyleft 2017']
    end

    before do
      subject.stub(:applicable_files).and_return(%w[main.go])
      subject.stub(:licence_lines).and_return(licence)
      subject.stub(:check_file).and_return(nil)
    end

    it { should pass }
  end
end
