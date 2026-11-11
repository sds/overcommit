# frozen_string_literal: true

# Merge LCOV line hits across platforms and shards before enforcing coverage.
# Individual shards need not cover every line, and platform-specific lines may
# only run on one operating system.
lines = Hash.new(0)
ARGV.each do |path|
  source = nil
  File.foreach(path) do |record|
    case record
    when /^SF:(.+)/
      source = Regexp.last_match(1).strip
    when /^DA:(\d+),(\d+)/
      abort "Line coverage without a source file in #{path}" unless source
      lines[[source, Regexp.last_match(1).to_i]] += Regexp.last_match(2).to_i
    when /^end_of_record/
      source = nil
    end
  end
end
abort 'No line coverage found' if lines.empty?

uncovered = lines.select { |_, hits| hits == 0 }.keys
unless uncovered.empty?
  warn "Uncovered lines:\n#{uncovered.sort.map { |file, line| "#{file}:#{line}" }.join("\n")}"
  abort '100% line coverage is required'
end
puts "Line coverage: 100% (#{lines.size}/#{lines.size})"
