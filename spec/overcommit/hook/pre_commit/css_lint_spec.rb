# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::CssLint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.css file2.css])
  end

  context 'when csslint exits successfully' do
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
      context 'with a line number' do
        before do
          result.stub(:stdout).and_return([
            'file1.css: line 1, col 5, Warning - Use of !important'
          ].join("\n"))
        end

        it { should warn }
      end

      context 'with no line number' do
        before do
          result.stub(:stdout).and_return([
            'file1.css: Warning - Too many !important declarations (10), try to use less than 10'
          ].join("\n"))
        end

        it { should warn }
      end
    end
  end

  context 'when csslint exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports an error' do
      context 'with a line number' do
        before do
          result.stub(:stdout).and_return([
            'file1.css: line 80, col 5, Error - Use of !important'
          ].join("\n"))
        end

        it { should fail_hook }
      end

      context 'with no line number' do
        before do
          result.stub(:stdout).and_return([
            'file1.css: Error - Currently no rules report a rollup error, but that may change'
          ].join("\n"))
        end

        it { should fail_hook }
      end
    end
  end
end
