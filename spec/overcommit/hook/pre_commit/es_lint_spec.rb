require 'spec_helper'

describe Overcommit::Hook::PreCommit::EsLint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.js file2.js])
  end

  context 'when eslint exits successfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    context 'with no output' do
      before do
        result.stub(:stdout).and_return('')
      end

      it { should pass }
    end

    context 'and it reports a warning' do
      before do
        result.stub(:stdout).and_return([
          'file1.js: line 1, col 0, Warning - Missing "use strict" statement. (strict)',
          '',
          '1 problem'
        ].join("\n"))
      end

      it { should warn }
    end
  end

  context 'when eslint exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports an error' do
      before do
        result.stub(:stdout).and_return([
          'file1.js: line 1, col 0, Error - Missing "use strict" statement. (strict)',
          '',
          '1 problem'
        ].join("\n"))
      end

      it { should fail_hook }
    end
  end
end
