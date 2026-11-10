# frozen_string_literal: true

require 'etc'
require 'digest'
require 'json'
require 'rbconfig'
require 'tmpdir'
require_relative '../spec/support/spec_shard'

if ARGV.first == '--worker'
  require 'rspec/core'
  exit RSpec::Core::Runner.run(JSON.parse(File.read(ARGV.fetch(1))))
end

# Examples change process-wide state (ENV and the working directory), so use
# processes, never threads. Split examples rather than files so large Git-heavy
# spec files don't leave one worker busy after the others have finished.
workers = Integer(ENV.fetch('SPEC_WORKERS') { [Etc.nprocessors, 8].min.to_s })
abort 'SPEC_WORKERS must be positive' unless workers > 0
shard = SpecShard.new(ENV.fetch('SPEC_SHARD', '1/1'))

Dir.chdir(File.expand_path('..', __dir__))
rspec = [RbConfig.ruby, Gem.bin_path('rspec-core', 'rspec')]
paths = ARGV.empty? ? ['spec'] : ARGV
started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

Dir.mktmpdir('overcommit-specs') do |tmpdir|
  discovery = File.join(tmpdir, 'discovery.json')
  unless system({ 'OVERCOMMIT_SPEC_DISCOVERY' => '1' }, *rspec, *paths,
                '--dry-run', '--format', 'json', '--out', discovery)
    abort 'RSpec discovery failed'
  end
  all_ids = JSON.parse(File.read(discovery)).fetch('examples').map { |example| example.fetch('id') }
  abort 'RSpec discovery found no examples' if all_ids.empty?

  ids = shard.select(all_ids)
  abort "Shard #{shard} has no examples" if ids.empty?
  puts "Discovered #{all_ids.size} examples (SHA256: #{Digest::SHA256.hexdigest(all_ids.join("\n"))})"

  groups = Array.new([workers, ids.size].min) { [] }
  ids.each_with_index { |id, index| groups[index % groups.size] << id }
  puts "Running shard #{shard}: #{ids.size}/#{all_ids.size} examples in #{groups.size} processes"

  processes = groups.each_with_index.map do |group, index|
    prefix = File.join(tmpdir, "worker-#{index}")
    # Read arguments inside the worker to avoid Windows' command-line limit.
    args = group + ['--format', 'progress', '--profile', '5',
                    '--format', 'json', '--out', "#{prefix}.json"]
    File.write("#{prefix}.arguments.json", JSON.generate(args))
    env = {
      'OVERCOMMIT_SPEC_WORKER' => index.to_s,
      'OVERCOMMIT_SPEC_COVERAGE_DIR' => "#{prefix}-coverage",
    }
    pid = Process.spawn(env, RbConfig.ruby, __FILE__, '--worker', "#{prefix}.arguments.json",
                        out: "#{prefix}.log", err: [:child, :out])
    [pid, prefix]
  end

  passed = true
  actual_ids = []
  processes.each_with_index do |(pid, prefix), index|
    _, status = Process.wait2(pid)
    puts "\n--- Worker #{index + 1} ---"
    puts File.read("#{prefix}.log")
    passed = false unless status.success?
    if File.exist?("#{prefix}.json")
      results = JSON.parse(File.read("#{prefix}.json"))
      actual_ids.concat(results.fetch('examples').map { |example| example.fetch('id') })
    end
  end

  # Fail if a configuration/filter change accidentally omits or duplicates any
  # examples. This checks identities, not just a potentially misleading count.
  unless actual_ids.sort == ids.sort
    warn 'The executed examples do not match the discovered suite'
    passed = false
  end

  resultsets = processes.map { |_, prefix| "#{prefix}-coverage/.resultset.json" }
  if resultsets.all? { |path| File.exist?(path) }
    require_relative '../spec/coverage_config'
    SimpleCov.collate(resultsets)
  else
    warn 'Missing worker coverage results'
    passed = false
  end

  elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
  puts "\nVerified #{actual_ids.size}/#{ids.size} examples in #{elapsed.round(2)} seconds"
  exit(passed ? 0 : 1)
end
