require 'spec_helper'

describe Overcommit::Hook::PreCommit::HtmlHint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.html file2.html])
  end

  context 'when htmlhint exits successfully' do
    let(:result) { double('result') }

    before do
      subject.stub(:execute).and_return(result)
    end

    context 'with no errors' do
      before do
        result.stub(:stdout).and_return('')
      end

      it { should pass }
    end

    context 'and it reports an error' do
      before do
        result.stub(:stdout).and_return([
          'file1.html:',
          "\tline 355, col 520: \e[31mId redefinition of [ stats ].\e[39m",
          '',
          '',
          '1 problem.'
        ].join("\n"))
      end

      it { should fail_hook }
    end
  end
end
