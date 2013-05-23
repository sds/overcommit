require 'spec_helper'
require 'overcommit/cli'

describe Overcommit::CLI do
  describe '#parse_arguments' do
    subject do
      cli = described_class.new(arguments)
      cli.parse_arguments
      cli
    end

    context 'with no arguments' do
      let(:arguments) { [] }

      it 'does not set any targets' do
        subject.options[:targets].should be_empty
      end
    end

    context 'with excludes' do
      let(:arguments) { %w[--exclude hook_name.first,hook_name/second] }

      it 'takes the first part of the name' do
        subject.options[:excludes]['hook_name'].should_not be_nil
      end

      it 'creates an array of excludes' do
        subject.options[:excludes]['hook_name'].should =~ %w[first second]
      end
    end
  end
end
