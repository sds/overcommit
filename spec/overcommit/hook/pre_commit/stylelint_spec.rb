# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::Stylelint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.scss file2.scss])
  end

  context 'when stylelint exits successfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(true)
      result.stub(:stderr).and_return('')
      result.stub(:stdout).and_return('')
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when stylelint exits unsucessfully with messages on stdout (stylelint < 16)' do
    let(:result) { double('result') }

    before do
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports an error' do
      before do
        result.stub(:success?).and_return(false)
        result.stub(:stderr).and_return('')
        result.stub(:stdout).and_return([
          'index.css: line 4, col 4, error - Expected indentation of 2 spaces (indentation)',
          'form.css: line 10, col 6, error - Expected indentation of 4 spaces (indentation)',
        ].join("\n"))
      end

      it { should fail_hook }

      it 'extracts lines numbers correctly from output' do
        expect(subject.run.map(&:line)).to eq([4, 10])
      end
    end
  end

  context 'when stylelint exits unsucessfully with messages on stderr (stylelint >= 16)' do
    let(:result) { double('result') }

    before do
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports an error' do
      before do
        result.stub(:success?).and_return(false)
        result.stub(:stdout).and_return('')
        result.stub(:stderr).and_return([
          'index.css: line 4, col 4, error - Expected indentation of 2 spaces (indentation)',
          'form.css: line 10, col 6, error - Expected indentation of 4 spaces (indentation)',
        ].join("\n"))
      end

      it { should fail_hook }

      it 'extracts lines numbers correctly from output' do
        expect(subject.run.map(&:line)).to eq([4, 10])
      end
    end
  end
end
