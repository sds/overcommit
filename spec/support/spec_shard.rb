# frozen_string_literal: true

# Deterministically partitions examples across CI runners before each runner
# distributes its share among local worker processes.
class SpecShard
  attr_reader :index, :total

  def initialize(value)
    match = %r{\A([1-9]\d*)/([1-9]\d*)\z}.match(value)
    raise ArgumentError, 'SPEC_SHARD must be INDEX/TOTAL (for example, 1/3)' unless match

    @index, @total = match.captures.map(&:to_i)
    raise ArgumentError, 'SPEC_SHARD index must not exceed total' if index > total
  end

  def select(examples)
    examples.each_with_index.select { |_, offset| offset % total == index - 1 }.map(&:first)
  end

  def to_s
    "#{index}/#{total}"
  end
end
