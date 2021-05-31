# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::YardCoverage do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.rb file2.rb])
  end

  context 'when yard exits successfully' do
    before do
      result = double('result')
      result.stub(:stdout).and_return(
        <<-HEREDOC
      Files:          72
      Modules:        12 (    0 undocumented)
      Classes:        63 (    0 undocumented)
      Constants:      91 (    0 undocumented)
      Attributes:     11 (    0 undocumented)
      Methods:       264 (    0 undocumented)
      100.0% documented
      HEREDOC
      )
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when somehow yard exits a non-stats output' do
    before do
      result = double('result')
      result.stub(:stdout).and_return(
        <<-HEREDOC
        WHATEVER OUTPUT THAT IS NOT YARD STATS ONE
      HEREDOC
      )
      subject.stub(:execute).and_return(result)
    end

    it { should warn }
  end

  context 'when somehow yard coverage is not a valid value' do
    before do
      result = double('result')
      result.stub(:stdout).and_return(
        <<-HEREDOC
      Files:          72
      Modules:        12 (    0 undocumented)
      Classes:        63 (    0 undocumented)
      Constants:      91 (    0 undocumented)
      Attributes:     11 (    0 undocumented)
      Methods:       264 (    0 undocumented)
      AAAAAA documented
      HEREDOC
      )
      subject.stub(:execute).and_return(result)
    end

    it { should warn }
  end

  context 'when yard exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports an error' do
      before do
        result.stub(:stdout).and_return(
          <<-HEREDOC
        Files:          72
        Modules:        12 (    3 undocumented)
        Classes:        63 (   15 undocumented)
        Constants:      91 (   79 undocumented)
        Attributes:     11 (    0 undocumented)
        Methods:       264 (   55 undocumented)
        65.53% documented

        Undocumented Objects:
        ApplicationCable                                                  (app/channels/application_cable/channel.rb:1)
        ApplicationCable::Channel                                         (app/channels/application_cable/channel.rb:2)
        ApplicationCable::Connection                                      (app/channels/application_cable/connection.rb:2)
        HEREDOC
        )
      end

      it { should fail_hook }
    end
  end
end
