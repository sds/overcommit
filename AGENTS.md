# Repository guidance

- Maintain **100% line coverage** across the complete test suite. Add thorough
  regression tests for new behavior and failure paths; do not exclude production
  code from coverage or lower the threshold to make checks pass.
- Preserve existing tests unless they specifically test an implementation that
  is being replaced. Prefer updating those tests to assert observable behavior.
- Run `bundle exec ruby script/parallel_rspec.rb` for the full suite and
  `bundle exec overcommit --run` for lint checks before submitting changes.
- Keep iterating on pull requests until all CI checks pass. Do not merge unless
  explicitly instructed to do so.
