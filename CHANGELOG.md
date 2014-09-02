# Overcommit Changelog

## master (unreleased)

* Change commit hook header text to bold instead of bold white so that it
  displays on terminals with a white background
* Add support for `OVERCOMMIT_DISABLE` environment variable, which when set
  prevents Overcommit hooks from running
* Fix bug that prevented RailsSchemaUpToDate from working in directories that
  contained decimals
* Warn when trying to pipe commands using the `execute` helper, as this is not
  supported

## 0.16.0

* Fix edge case where hitting Ctrl-C twice rapidly could result in work
  tree being lost
* Fix edge case where hitting Ctrl-C after all pre-commit hooks had run
  but before the cleanup had finished would result in a lost working
  tree
* Handle edge case where if a file was created in the working directory by a
  separate process in between the working tree being reset and the stash being
  applied, the hook runner would silently fail
* Prevent stack traces from appearing during early interrupt before Overcommit
  has loaded its code
* Remove `BundleCheck` post-checkout hook as it was a bit overzealous

## 0.15.0

* Fix bug where incorrect "hook run interrupted" message displayed when
  hook run failed
* Gracefully handle `git stash` failures in pre-commit hook runs
* Fix `overcommit-hook` auto-updating not passing original arguments to
  updated hook
* Display message when `overcommit-hook` file is automatically updated
* Deprecate `:bad` status in favor of `:fail`
* Deprecate `:good` status in favor of `:pass`
* Allow hook statuses to be transformed via `on_fail` and `on_warn`
  configuration options
* Add `config` attribute as the preferred method to access hook
  configurations in hook implementations
* Generate starter configuration on install with instructions on how to
  configure overcommit if an `.overcommit.yml` file does not yet exist
* Include name of hook in output (to make it easier to find out which name
  to use when skipping)

## 0.14.1

* Fix hook skipping regression

## 0.14.0

* Ignore `db/structure.sql` in `TrailingWhitespace` pre-commit hook
* Drop stashed changes after restoring them (now that #55 is fixed)
* Change `JSCS` pre-commit hook to check status code instead of using
  regex to determine type of error
* Fix performance regression where running Overcommit in a repository
  with a lot of files would be very slow
* Wildcards in include/exclude globs now match files beginning with `.`
* Drop support for Ruby 1.8.7

## 0.13.0

* Prevent `JsonSyntax` pre-commit hook from failing if `json_class` key
  is present in JSON
* Prevent `HardTabs` pre-commit hook from warning on tabs in Makefiles
* Fix bug where `overcommit` hooks would fail for initial commit to repo
* Add support for gracefully exiting from Ctrl-C interruptions
* Add `.gitmodules` to the list of ignored files in `HardTabs` pre-commit hook

## 0.12.0

* Skip `HardTabs` pre-commit hook for Golang source files by default
* Disable `IndexTags` post-checkout hook by default
* Add `GoLint` pre-commit hook which runs `golint` on Golang source files

## 0.11.1

* Fix bug where `CHERRY_PICK_HEAD` would be lost when a pre-commit hook failed
  after attempting to cherry pick a commit with a conflict
* Drop support for Ruby 1.9.2

## 0.11.0

* Allow custom arguments to be passed to `ctags` via `IndexTags` post-checkout
  hook

## 0.10.0

* Change format of `include`/`exclude` file globs to match that of standard
  shell globbing (e.g. `**` matches zero or more directories rather than 1 or
  more)
* Don't drop stashed changes after restoring them
* Fix bug where `MERGE_HEAD` would be lost when attempting to commit a
  resolution to a merge conflict

## 0.9.0

* Include `--force-exclusion` flag in Rubocop hook so files excluded via
  `.rubocop.yml` are actually excluded
* Add pre-commit `JsxHint` hook which uses the
  [JSXHint](https://github.com/STRML/JSXHint) project
* Add pre-commit `BerksfileCheck` hook which warns you when your
  `Berksfile.lock` is out of sync with your `Berksfile`
* Fix `BundleCheck` to use `git ls-files` instead of `git check-ignore`,
  as the latter is only available as of git 1.8
* Fix bug where skipping a hook via the `SKIP` environment variable would
  incorrectly warn about the hook's configuration having changed
* Add `MergeConflicts` pre-commit hook which checks for unresolved merge
  conflicts in files
* Add `RailsSchemaUpToDate` pre-commit hook which checks for
  `schema.rb`/`structure.sql` that aren't up-to-date with the latest migration
* Add `PryBinding` pre-commit hook which checks for `binding.pry` calls that
  have been left behind in code
* Add `LocalPathsInGemfile` pre-commit hook which checks for gem dependencies
  pointing to local paths in a `Gemfile`
* Add `JsonSyntax` pre-commit hook which checks the syntax of all `.json` files
* Add `Brakeman` pre-commit hook which runs security checks against code
  (disabled by default as it is slow)
* Add `ChamberSecurity` pre-commit hook which ensures that `chamber secure` has
  been run before committing your changes (see the
  [Chamber](https://github.com/thekompanee/chamber) gem for more information)

## 0.8.0

* Add pre-commit `TravisLint` hook which uses the
  [travis-lint](https://github.com/travis-ci/travis-lint) gem
* Display actual warning message when dependencies aren't satisfied in
  post-checkout `BundleCheck` hook
* Add support for hook plugin signature verification so that you don't
  automatically execute repo-specific hooks that changed since you last
  ran them. See [Security](https://github.com/causes/overcommit#security)
  for more information
* Automatically update `overcommit-hook` master hook and any other symlinks
  before hook run. Run `overcommit --install` if you're upgrading to save
  you from having to run `overcommit --install` in the future

## 0.7.0

* Change `command` hook helper signature to accept an array of arguments
  instead of a shell string
* Rename `command` hook helper to `execute`
* Add support for JRuby 1.7.9 in Ruby 1.9 mode
* Display more helpful error message when installing Overcommit into a repo
  that already has non-Overcommit hooks
* Add `--force` flag allowing Overcommit to be installed in repositories that
  already contain non-Overcommit hooks (overwriting them in the process)

## 0.6.3

* `TextWidth` pre-commit hook now supports customized maximum subject line
  and commit message body widths
* Fix bug where committing a change with only file deletions would result
  in those changes not being committed
* Warn instead of failing when gem dependencies are out of date in
  `BundleCheck` post-checkout hook

## 0.6.2

* Fix bug where hook run would crash if hook was unsuccessful but returned no
  output

## 0.6.1

* Fix bug where a plugin would fail to load if it had a custom configuration
  defined

## 0.6.0

* Breaking changes: plugin framework has been overhauled.
  You must now subclass `Overcommit::Hook::<Type>` and implement
  the method `run` instead of `run_check`. Also, the old hook runner
  no longer works, so you'll need to remove the hooks installed in
  `.git/hooks` and install new ones with `overcommit --install`
* Configuration for repository can be specified via `.overcommit.yml` file
* Can now skip hooks using just `SKIP` instead of `SKIP_CHECKS` environment
  variable
* Add `--template-dir` flag which provides a convenient way to auto-install
  overcommit via Git template directories
* Converted all script-based hook scripts to Ruby-based ones
* `AuthorEmail` check can be customized so emails match a regex
* `Whitespace` check was split into `HardTabs` and `TrailingWhitespace`
* Add pre-commit JavaScript style checking with
  [JSCS](https://github.com/mdevils/node-jscs)
* Add `BundleCheck` pre-commit hook which checks if `Gemfile.lock` matches
  `Gemfile`

## 0.5.0

* Use per-file `.scss-lint.yml` configuration for staged files

## 0.4.1

* Remove `RestrictedPaths` pre-commit check

## 0.4.0

* Added pre-commit check that optimizes images with `image_optim`
* Don't include submodules in the list of modified files

## 0.3.2

* Fix bug where `.rubocop.yml` would not be found in present working directory

## 0.3.1

* Use per-file `.rubocop.yml` configuration for staged files

## 0.3.0

* Added Gemfile.lock/bundler checking
* Added `--no-ext-diff` option to git diff
* Exposed StagedFile#original_path

## 0.2.6

* Added check for linting HAML files with
  [haml-lint](https://github.com/causes/haml-lint)

## 0.2.5

* Don't use `--silent` flag with `rubocop` for Ruby style check
  (allows upgrade to Rubocop 0.12.0)

## 0.2.4

* Teach scss-lint check to downgrade lints on untouched lines as warnings

## 0.2.3

* Fix "Too many open files" error for very large commits
* Make `StagedFile` tempfile creation lazy - should speed up some checks
* Address rare cross-platform compatibility issue by replacing a `which`
  call with a pure Ruby equivalent
* Fix CoffeeScript linter path processing

## 0.2.2

* Allow specifying multiple file types for checks and syntax check rake files
* Fix bug where checks which returned lists of lines would output incorrectly
* Indent check output lines to nest under check name for better readability

## 0.2.1

* Fix bug where checks that didn't return strings for output would error

## 0.2.0

* Teach `StagedFile`s how to calculate which lines were actually added/modified
* Checks no longer need to filter temporary staged file paths themselves
* Condense Ruby style check output
* Teach Ruby style check to downgrade style lints on untouched lines as warnings

## 0.1.11

* Added Ruby code style linting via RuboCop

## 0.1.10

* Fixed bug where `output` was expected to be a string but was an array in
  js_syntax

## 0.1.9

* Fixed bug where `staged` helper in `HookSpecificCheck` wasn't returning
  `StagedFile`s

## 0.1.8

* Resurrect StagedFile for reading index contents rather than disk contents

## 0.1.7

* Sort plugins alphabetically
* Omit periods from warning messages for consistency
* Enforce single-line commit message subjects
* Only colorize output when logging to a TTY
* Add check to detect hard tabs in commit messages
* Fix crashing --list-templates flag

## 0.1.6

* Strip out blank release note in addition to warning the committer
* Add Python linting via [flake8](http://flake8.readthedocs.org/en/latest/)
* Add CoffeeScript linting via [coffeelint](http://www.coffeelint.org/)

## 0.1.5

* Improve spec coverage
* Use installed `jshint` if available instead of Rhino
* Update readme with dependencies, uninstall instructions

## 0.1.4

* Fix SKIP_CHECKS for namespaced hooks
* Make hooks work when repo-specific configuration file is missing
* Improve error handling when loading custom hooks

## 0.1.3

* Add un-skippable checks (not skipped via SKIP_CHECKS)
* Improve spec coverage

## 0.1.2

* Add uninstall (-u) option

## 0.1.1

* Make installer more robust
* Improve readme documentation
* Add template listing (-l) to CLI
* Add rspec and super-basic spec coverage
* Improve command-line messaging

## 0.1.0

* First public release
