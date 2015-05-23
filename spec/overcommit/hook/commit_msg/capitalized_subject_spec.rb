# encoding: utf-8
require 'spec_helper'

describe Overcommit::Hook::CommitMsg::CapitalizedSubject do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    context.stub(:commit_message_lines).and_return(commit_msg.split("\n"))
    context.stub(:empty_message?).and_return(commit_msg.empty?)
  end

  context 'when commit message is empty' do
    let(:commit_msg) { '' }

    it { should pass }
  end

  context 'when subject starts with a capital letter' do
    let(:commit_msg) { <<-MSG }
Initial commit

Mostly cats so far.
    MSG

    it { should pass }
  end

  context 'when subject starts with a utf-8 capital letter' do
    let(:commit_msg) { <<-MSG }
Årsgång

Mostly cats so far.
    MSG

    it { should pass }
  end

  context 'when subject starts with punctuation and a capital letter' do
    let(:commit_msg) { <<-MSG }
"Initial" commit

Mostly cats so far.
    MSG

    it { should pass }
  end

  context 'when subject starts with a lowercase letter' do
    let(:commit_msg) { <<-MSG }
initial commit

I forget about commit message standards and decide to not capitalize my
subject. Still mostly cats so far.
    MSG

    it { should warn }
  end

  context 'when subject starts with a utf-8 lowercase letter' do
    let(:commit_msg) { <<-MSG }
årsgång

I forget about commit message standards and decide to not capitalize my
subject. Still mostly cats so far.
    MSG

    it { should warn }
  end

  context 'when subject starts with punctuation and a lowercase letter' do
    let(:commit_msg) { <<-MSG }
"initial" commit

I forget about commit message standards and decide to not capitalize my
subject. Still mostly cats so far.
    MSG

    it { should warn }
  end
end
