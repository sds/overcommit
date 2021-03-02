# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::EsLint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.js file2.js])
  end

  context 'when eslint is unable to run' do
    let(:result) { double('result') }

    before do
      result.stub(:stderr).and_return('SyntaxError: Use of const in strict mode.')
      result.stub(:stdout).and_return('')

      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    it { should fail_hook }
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

    context 'and it doesnt count false positives error messages' do
      before do
        result.stub(:stdout).and_return([
          '$ yarn eslint --quiet --format=compact /app/project/Error.ts',
          '$ /app/project/node_modules/.bin/eslint --quiet --format=compact /app/project/Error.ts',
          '',
        ].join("\n"))
      end

      it { should pass }
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
