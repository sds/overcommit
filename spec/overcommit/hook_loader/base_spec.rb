# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::HookLoader::Base do
  it 'requires subclasses to implement hook loading' do
    loader = described_class.new(double('config'), double('context'), Overcommit::Logger.silent)
    expect { loader.load_hooks }.to raise_error(NotImplementedError)
  end
end
