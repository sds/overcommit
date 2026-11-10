# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Utils::MessagesUtils do
  it 'rejects an empty captured filename' do
    expect { described_class.extract_messages([':1'], /(?<file>.*):(?<line>\d+)/) }.
      to raise_error(Overcommit::Exceptions::MessageProcessingError, /no file found/)
  end

  it 'rejects an invalid captured line number' do
    expect { described_class.extract_messages(['file:bad'], /(?<file>.*):(?<line>.*)/) }.
      to raise_error(Overcommit::Exceptions::MessageProcessingError, /invalid line number/)
  end

  it 'rejects an invalid categorized type' do
    expect { described_class.extract_messages(['file'], /(?<file>.*)/, ->(_) { :invalid }) }.
      to raise_error(Overcommit::Exceptions::MessageProcessingError, /Invalid message type/)
  end
end
