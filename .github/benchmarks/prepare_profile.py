from pathlib import Path
root=Path.cwd()
source=(root/'script/parallel_rspec.rb').read_text()
source=source.replace('      results = JSON.parse(File.read("#{prefix}.json"))\n', '      results = JSON.parse(File.read("#{prefix}.json"))\n      File.write(File.join(ENV.fetch("BENCHMARK_RESULTS_DIR"), "worker-#{index}.json"), JSON.generate(results.fetch("examples")))\n')
source=source.replace('  exit(passed ? 0 : 1)', '''  File.write(File.join(ENV.fetch('BENCHMARK_RESULTS_DIR'), 'summary.json'), JSON.pretty_generate(
    elapsed: elapsed, passed: passed, suite_size: all_ids.size,
    suite_digest: Digest::SHA256.hexdigest(all_ids.join("\\n")),
    selected: ids.size, executed: actual_ids.size,
    shard: shard.to_s, workers: workers, ruby: RUBY_VERSION, platform: RUBY_PLATFORM
  ))
  exit(passed ? 0 : 1)''')
(root/'coverage').mkdir(exist_ok=True)
(root/'coverage/benchmark_rspec.rb').write_text(source)
