# Repository guidance

- Maintain **100% line and branch coverage**, aggregated across the complete
  test suite and all CI platforms, Ruby versions, and shards. Individual shards
  need not reach 100%; the combined coverage report must. Add thorough
  regression tests for new behavior and failure paths; do not exclude production
  code from coverage or lower the threshold to make checks pass.
- Preserve existing tests unless they specifically test an implementation that
  is being replaced. Prefer updating those tests to assert observable behavior.
- Run `bundle exec ruby script/parallel_rspec.rb` for the full suite and
  `bundle exec overcommit --run` for lint checks before submitting changes.
- Keep iterating on pull requests until all CI checks pass. Do not merge unless
  explicitly instructed to do so.
