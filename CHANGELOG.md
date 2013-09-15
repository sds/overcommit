master (unreleased)

* Added check for linting HAML files with
  [haml-lint](https://github.com/causes/haml-lint)

0.2.5

* Don't use `--silent` flag with `rubocop` for Ruby style check
  (allows upgrade to Rubocop 0.12.0)

0.2.4

* Teach scss-lint check to downgrade lints on untouched lines as warnings

0.2.3

* Fix "Too many open files" error for very large commits
* Make `StagedFile` tempfile creation lazy - should speed up some checks
* Address rare cross-platform compatibility issue by replacing a `which`
  call with a pure Ruby equivalent
* Fix CoffeeScript linter path processing

0.2.2

* Allow specifying multiple file types for checks and syntax check rake files
* Fix bug where checks which returned lists of lines would output incorrectly
* Indent check output lines to nest under check name for better readability

0.2.1

* Fix bug where checks that didn't return strings for output would error

0.2.0

* Teach `StagedFile`s how to calculate which lines were actually added/modified
* Checks no longer need to filter temporary staged file paths themselves
* Condense Ruby style check output
* Teach Ruby style check to downgrade style lints on untouched lines as warnings

0.1.11

* Added Ruby code style linting via RuboCop

0.1.10

* Fixed bug where `output` was expected to be a string but was an array in
  js_syntax

0.1.9

* Fixed bug where `staged` helper in `HookSpecificCheck` wasn't returning
  `StagedFile`s

0.1.8

* Resurrect StagedFile for reading index contents rather than disk contents

0.1.7

* Sort plugins alphabetically
* Omit periods from warning messages for consistency
* Enforce single-line commit message subjects
* Only colorize output when logging to a TTY
* Add check to detect hard tabs in commit messages
* Fix crashing --list-templates flag

0.1.6

* Strip out blank release note in addition to warning the committer
* Add Python linting via [flake8](http://flake8.readthedocs.org/en/latest/)
* Add CoffeeScript linting via [coffeelint](http://www.coffeelint.org/)

0.1.5

* Improve spec coverage
* Use installed `jshint` if available instead of Rhino
* Update readme with dependencies, uninstall instructions

0.1.4

* Fix SKIP_CHECKS for namespaced hooks
* Make hooks work when repo-specific configuration file is missing
* Improve error handling when loading custom hooks

0.1.3

* Add un-skippable checks (not skipped via SKIP_CHECKS)
* Improve spec coverage

0.1.2

* Add uninstall (-u) option

0.1.1

* Make installer more robust
* Improve readme documentation
* Add template listing (-l) to CLI
* Add rspec and super-basic spec coverage
* Improve command-line messaging

0.1.0

* First public release
