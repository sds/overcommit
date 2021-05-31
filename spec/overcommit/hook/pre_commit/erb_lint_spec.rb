# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::ErbLint do
  let(:config) { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.html.erb file2.html.erb])
  end

  context 'when erblint exits successfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when erblint exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports an error' do
      before do
        result.stub(:stdout).and_return(<<-MSG)
Linting 1 files with 14 linters...

erb interpolation with '<%= (...).html_safe %>' in this context is never safe
In file: app/views/posts/show.html.erb:10
        MSG
      end

      it { should fail_hook }
    end
  end
end
