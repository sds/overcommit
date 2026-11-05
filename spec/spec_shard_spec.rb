# frozen_string_literal: true

require 'spec_helper'

describe SpecShard do
  let(:examples) { (1..17).map { |index| "example-#{index}" } }

  it 'runs the complete suite when using a single shard' do
    described_class.new('1/1').select(examples).should == examples
  end

  [2, 3, 5].each do |total|
    context "with #{total} shards" do
      let(:shards) do
        (1..total).map { |index| described_class.new("#{index}/#{total}").select(examples) }
      end

      it 'assigns every example to exactly one shard' do
        shards.flatten.sort.should == examples.sort
      end

      it 'balances example counts within one example' do
        counts = shards.map(&:size)
        (counts.max - counts.min).should <= 1
      end

      it 'assigns examples deterministically in their original order' do
        shards.first.should == examples.each_slice(total).map(&:first)
      end
    end
  end

  it 'handles more shards than examples without duplicating examples' do
    described_class.new('3/3').select(['only-example']).should == []
  end

  ['', '1', '0/2', '1/0', '3/2', '-1/2', '1/2/3', '1/2junk'].each do |value|
    it "rejects the invalid shard #{value.inspect}" do
      expect { described_class.new(value) }.to raise_error(ArgumentError, /SPEC_SHARD/)
    end
  end
end
