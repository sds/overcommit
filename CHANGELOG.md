# Overcommit Changelog

## 0.32.0

### New Features

* Hooks are now run in parallel by default
* Add `concurrency` global option allowing you to specify the number of threads
  to use when running hooks concurrently
* Add `parallelize` hook option which specifies whether or not this hook should
  be run in parallel (default is `true`)
* Add `processors` hook option allowing you to specify how many processing
  units a hook should require
* Add `ForbiddenBranches` pre-commit hook which prevents creating a commit
  on any blacklisted branch by name/pattern
* Add `MessageFormat` commit-msg hook to validate commit messages against
  a regex pattern

### Changes

* Improve error message output when there is a problem processing messages
  via `extract_messages` pre-commit hook helper
* Switch `ScssLint` pre-commit hook to use the JSON output formatter instead
  of the default formatter
* Change tense of hook descriptions from progressive indicative form ("Running")
  to indicative present form ("Run") so output reads better in parallel hook
  runs

### Bug Fixes

* Fix bug where amending a commit with command line arguments containing
  Unicode characters could cause a crash due to invalid byte sequences
* Fix `Minitest` pre-push hook to include all test files

## 0.32.0.rc1

* Add `concurrency` global option allowing you to specify the number of threads
  to use when running hooks concurrently
* Add `parallelize` hook option which specifies whether or not this hook should
  be run in parallel (default is `true`)
* Add `processors` hook option allowing you to specify how many processing
  units a hook should require

## 0.31.0

* Add support for glob patterns to `ProtectedBranches` pre-push hook
* Add `Mdl` pre-commit hook to run
  [`mdl`](https://github.com/mivok/markdownlint) on Markdown files
* Add `--without-color` flag to `RailsBestPractices` pre-commit hook
  to fix parsing issues due to color escape sequences
* Improve error message when `gemfile` has not had a dependency installed
* Fix `RuboCop` pre-commit hook to not swallow cop messages when `parser` gem
  warnings are output to STDERR

## 0.30.0

### New Features

* Add `Dogma` pre-commit hook to lint Elixir files with
  [dogma](http://elixir-lang.org/) files
* Add `Minitest` pre-push hook to run Minitest tests
* Add `RailsBestPractices` pre-commit hook which lints code with
  [`rails_best_practices`](https://github.com/railsbp/rails_best_practices)

### Bug Fixes

* Fix `--run` flag to not block reading STDIN when using existing hook scripts
* Fix `RuboCop` pre-commit hook to fail when RuboCop version specified by
  Bundler context is not available
* Fix `TextWidth` commit-msg hook to not include newline characters in
  calculated width

## 0.29.1

* Raise error when hooks are defined with invalid names (i.e. non-alphanumeric
  characters)
* Fix hook signing when specifying hook name
* Fix `BundleCheck` pre-commit hook to not report false negatives when running
  via `overcommit --run` with local changes

## 0.29.0

### Important Security Fix

* Fix vulnerability where disabling signature verification would not be caught
  by signature verification, allowing an attacker to bypass the check. If you
  disable signature verification in your configuration, you must rename the
  option to `verify_signatures` and should audit your hooks.

### New Features

* Allow nested arrays in `include` and `exclude` options so lists of file
  glob patterns can be shared across hook configurations via YAML references
* Add `NginxTest` pre-commit hook that checks nginx configuration files with
  [`nginx -t`](https://www.nginx.com/resources/wiki/start/topics/tutorials/commandline/)
* Respect `core.commentchar` configuration when reading commit messages

### Changes

* Rename `verify_plugin_signatures` to `verify_signatures`

### Bug Fixes

* Fix `Jscs` pre-commit hook to handle the new `jscs`
  [exit codes](https://github.com/jscs-dev/node-jscs/wiki/Exit-codes) introduced
  as of 2.2.0
* Fix `Scalastyle` pre-commit hook to fail with non-zero exit statuses

## 0.28.0

* Ensure `applicable_files` hook helper returns files in lexicographic order
* Add `NpmInstall` post-checkout, post-commit, post-merge, and post-rewrite hooks
* Add `PuppetLint` pre-commit hook that checks Puppet code with
  [puppet-lint](http://puppet-lint.com/)
* Add `BowerInstall` post-checkout, post-commit, post-merge, and post-rewrite hooks
* Add `BundleInstall` post-checkout, post-commit, post-merge, and post-rewrite hooks
* Add `Sqlint` pre-commit hook that checks SQL code with
  [sqlint](https://github.com/purcell/sqlint)
* Add Windows support
* Add `Hlint` pre-commit hook that checks Haskell files with
  [hlint](https://github.com/ndmitchell/hlint)
* Add `ExecutePermissions` pre-commit hook that checks file mode for
  unnecessary execute permissions

## 0.27.0

### New Features

* Add `HtmlHint` pre-commit hook that checks HTML files with
  [HTMLHint](http://htmlhint.com/)
* Add support to the hook `execute` helper for accepting an optional list of
  splittable command arguments for transparently dealing with really long file
  lists and the operating system command length limit
* Add `modified_files` helper to `PostCheckout` and `PostRewrite` hooks
* Add `rewritten_commits` helper to `PostRewrite` hooks
* Add `gemfile` option to configuration file which allows a `Gemfile` to be
  loaded by Bundler to enforce particular gem versions during hook runs
* Add support for `OVERCOMMIT_DEBUG` environment variable which toggles the
  display of additional verbose output from executed commands
* Add support for defining
  [hooks based on your existing git hooks](README.md#adding-existing-git-hooks)
  within your `.overcommit.yml` (no Ruby code required)
* Add support for filtering all hooks except a small list via the `ONLY`
  environment variable (similar to `SKIP` except a whitelist instead of
  blacklist)

### Changes

* Don't display "No applicable _hook-type_ hooks to run" message unless debug
  mode is enabled

### Bug Fixes

* Fix pre-commit hook bug where amending a commit which breaks a symlink would
  result in that symlink not being included in the list of modified files
* Fix `CaseConflicts` pre-commit hook handling of large sets of files
* Fix `SemiStandard`/`Standard` hooks to read from `STDOUT` instead of `STDERR`
  and handle new output format
* Fix `commit-msg` hooks to handle large commit messages auto-generated by the
  `--verbose` flag for `git commit`

## 0.26.0

### New Features

* Add `EmptyMessage` commit-msg hook that reports commits messages that are
  empty or contain only whitespace
* Add `env` hook configuration option that allows you to set values for
  environment variables during the course of a particular hook's run

### Bug Fixes

* Fix handling of paths with spaces in the name
* Fix `CaseConflicts` pre-commit hook to not fail on initial commit
* Fix handling of files removed or renamed in a commit amendment

## 0.25.0

### New Features

* Add `Vint` pre-commit hook that checks Vim script with
  [Vint](https://github.com/Kuniwak/vint)
* Add `Scalariform` pre-commit hook that checks formatting of Scala code with
  [Scalariform](https://mdr.github.io/scalariform/)
* Add `SlimLint` pre-commit hook that analyzes Slim templates with
  [Slim-Lint](https://github.com/sds/slim-lint)

### Changes

* Include SVG files in `ImageOptim`, `XmlLint`, and `XmlSyntax` pre-commit
  hooks by default
* Make `IndexTags` hooks quiet by default
* Rename `Rubocop` pre-commit hook to `RuboCop` to match the project's proper
  name

### Bug Fixes

* Fix `HardTabs` and `TrailingWhitespace` pre-commit hooks to include
  line information in errors, making it work as expected when
  `problem_on_unmodified_line` is set to something other than `report`
* Fix handling of changing a symlink to a directory on commit amendment so it
  is not included in the list of modified files for pre-commit hooks
* Handle empty commit messages in `CapitalizedSubject`, `SingleLineSubject`,
  `HardTabs`, `TextWidth`, and `TrailingPeriod` commit-msg hooks

## 0.24.0

### New Features

* Add `required_library`/`required_libraries` hook option which specifies
  a list of paths a hook should load with `Kernel.require` before running
* Add `JsLint` pre-commit hook that checks the style of JavaScript files with
  [JSLint](http://www.jslint.com/)
* Add `RubyLint` pre-commit hook that statically analyzes Ruby files with
  [ruby-lint](https://github.com/YorickPeterse/ruby-lint)
* Add `Jsl` pre-commit hook that checks the style of JavaScript files with
  [JavaScript Lint](http://www.javascriptlint.com/)
* Add `CapitalizedSubject` commit message hook
* Add `GoVet` pre-commit hook that examines Go source files with
  [vet](https://godoc.org/golang.org/x/tools/cmd/vet)
* Add `XmlSyntax` pre-commit hook to check that XML files are valid
* Add `CaseConflicts` pre-commit hook which checks for file names in the same
  directory which differ by letter casing
* Preserve existing git hooks in a repository when installing Overcommit hooks,
  and restore them on uninstall
* Add `RSpec` pre-push hook that runs [RSpec](http://rspec.info/) tests before
  pushing to remote
* Add `ProtectedBranches` pre-push hook that prevents destructive pushes
  (deletions or force pushes) to specified branches
* Add `SpellCheck` commit-msg hook to check commit messages for misspelled words
* Add support for `pre-rebase` hooks
* Add `SubmoduleStatus` `post-checkout`, `post-commit`, `post-merge`, and
  `post-rewrite` hooks that warn when submodules are uninitialized, out of date
  with the current index, or contain merge conflicts

### Changes

* Disable `ShellCheck` pre-commit hook by default
* Switch `ImageOptim` hook to use executable instead of Ruby API
* Improve `CoffeeLint` pre-commit hook to differentiate between errors and
  warnings
* Improve `GoLint` pre-commit hook to extract file and line information
* Change configuration loading behavior to prefer user-defined `ALL` hook
  configuration over default `ALL` configuration, and user-defined hook
  configuration over default `ALL` configuration
* Change hook summary message to mention warnings if there were any
* Disable almost all hooks by default. You will now need to explicitly enable
  almost all hooks yourself in your `.overcommit.yml`. If you are migrating from
  `overcommit` 0.23.0 and want to use the default configuration that shipped
  with that version, copy the [default configuration from 0.23.0](https://github.com/brigade/overcommit/blob/9f03e9c82b385d375a836ca7146b117dbde5c822/config/default.yml)
* Update `ScssLint` pre-commit hook to properly handle special exit code that
  signals all files were filtered by exclusions (new as of `scss-lint` 0.36.0)
* Update `childprocess` dependency to minimum 0.5.6
* Change default value for `problem_on_unmodified_line` from `warn` to `report`
* Update `Rubocop` pre-commit hook to pass `--display-cop-names` flag so
  cop names appear in output
* Drop support for returning `:good`/`:bad` results from hooks (was deprecated in
  0.15.0)
* Remove `PryBinding` pre-commit hook since its functionality is provided by the
  `Rubocop` pre-commit hook

### Bug Fixes

* Fix `LocalPathsInGemfile` to not report lints for commented paths
* Fix `CssLint` pre-commit hook to ignore blank lines in `csslint` output
* Fix error instructions typo in `BundleCheck` pre-commit hook
* Fix bug where stashed changes were not restored when plugin signature
  validation failed
* Don't clear working tree after pre-commit hook when only submodule changes
  are present
* Restore file modification times of unstaged files in addition to staged files
  in pre-commit hook runs

## 0.23.0

### New Features

* Add pre-commit [ESLint](http://eslint.org/) hook
* Add pre-commit hooks for [standard](https://github.com/feross/standard) and
  [semistandard](https://github.com/Flet/semistandard) JavaScript linters
* Add support for `post-commit`, `post-merge`, and `post-rewrite` hooks
* Add `GitGuilt` `post-commit` hook to display changes in blame ownership for
  modified files
* Add `execute_in_background` helper to provide a standardized way to start
  long-running processes without blocking the hook run
* Add `IndexTags` hook for `post-commit`, `post-merge`, and `post-rewrite`
  hook types so tags index can always be kept up to date via `ctags`
* Add `W3cCss` and `W3cHtml` pre-commit hooks which integrate with the
  `w3c_validator` gem
* Add `Scalastyle` pre-commit hook that runs
  [scalastyle](http://www.scalastyle.org/) against Scala code
* Add `XmlLint` pre-commit hook to check XML files with
  [xmllint](http://xmlsoft.org/xmllint.html)
* Add `JavaCheckstyle` pre-commit hook to check style of Java files with
  [checkstyle](http://checkstyle.sourceforge.net/)
* Add `Pep8` pre-commit hook to check Python files with
  [pep8](https://pypi.python.org/pypi/pep8)
* Add `Pyflakes` pre-commit hook to check Python files with
  [pyflakes](https://pypi.python.org/pypi/pyflakes)
* Add `Pep257` pre-commit hook to check Python files with
  [pep257](https://pypi.python.org/pypi/pep257)
* Add `HtmlTidy` pre-commit hook to check HTML files with
  [tidy](http://www.html-tidy.org/)
* Add `Pylint` pre-commit hook to check Python files with
  [pylint](http://www.pylint.org/)

### Changes

* Parse JSHint errors more precisely
* Remove `JsxHint` and `Jsxcs` pre-commit hooks in favor of using the
  `required_executable` option on the JsHint and Jscs pre-commit hooks
* Change behavior of configuration options containing array values to always
  replace the old value instead of appending to it
* Change `ImageOptim` hook to fail instead of warn if the `image_optim` gem
  cannot be found
* Remove `ctags_arguments` option from `IndexTags` hooks
* Improve `PythonFlake8` pre-commit hook to differentiate between errors
  and warnings
* Improve `CssLint` pre-commit hook to differentiate between errors and
  warnings

### Bug Fixes

* Fix `--run` flag to consider all lines in all files as modified rather than none
* Fix `--run` flag to exclude submodule directories from the list of modified files
* Fix handling of files with spaces in their name when calculating modified
  lines in a file

## 0.22.0

* Disable `Reek` pre-commit hook by default
* Allow `required_executable` to include paths that are in the repo root
* Add `command` hook option allowing the actual command that is executed
  to be configured (useful to invoke command via `bundle exec` or similar)
* Add `flags` hook option allowing the flags passed on the command line
  to be configured

## 0.21.0

* Change `HardTabs`, `MergeConflicts`, and `PryBinding` pre-commit hooks to
  be `quiet` by default
* Switch `TravisLint` pre-commit hook from deprecated `travis-lint` gem to
  `travis` gem
* Add .projections.json configuration file
* Add pre-commit static analysis and linting for sh/bash scripts with
  [ShellCheck](http://www.shellcheck.net/)
* Use `--verbose` flag when running JSCS to include name of offending rule

## 0.20.0

* Add `--run` flag which runs all configured pre-commit hooks against the
  entire repository
* Fix installer to work with Overcommit hooks created via `GIT_TEMPLATE_DIR`
* Fix hook runner to not display skip message unless hook would have actually
  run
* Change `ImageOptim` hook to use `skip_missing_workers` option and update
  dependency to 0.18.0
* Remove interactive prompt support from overcommit hooks
* Change hook signing from interactive flow to be done via
  `overcommit --sign <hook-type>` command

## 0.19.0
* Add `--no-pngout` flag for `image_optim` command on `:fail` message
* Fix `Brakeman` pre-commit hook when multiple files have been staged
* Reset modification times more frequently when cleaning up the environment
  after running pre-commit hooks. This should help overcommit work with file
  watchers a little more nicely.
* Add pre-commit JavaScript style checking with
  [JSXCS](https://github.com/orktes/node-jsxcs)
* Add pre-commit Ruby code smell checking with
  [Reek](https://github.com/troessner/reek)
* Gracefully handle `.git` files that point to an external git directory

## 0.18.0

* Update minimum version of `image_optim` gem to 0.15.0 (breaking change in
  name of exception classes)
* Add `--list-hooks` flag which displays all hooks for a repository and
  whether they are enabled/disabled
* Add `required_executable` and `install_command` options that allow a hook
  to define an executable that must be in the `PATH` in order for it to work,
  and a command the user can use to install the executable if it doesn't exist
* All built-in hooks will now fail if the required executable is not present
* Fix bug where pre-commit hook would crash if user attempted to commit a
  broken symlink
* Add `BrokenSymlinks` pre-commit hook which checks for broken symlinks
* Fix Chamber integration
* Fix 'include' path for ChamberSecurity
* Fix bug where commit message from cherry-picked commit would be lost if
  there were conflicts

## 0.17.0

* Change commit hook header text to bold instead of bold white so that it
  displays on terminals with a white background
* Add support for `OVERCOMMIT_DISABLE` environment variable, which when set
  prevents Overcommit hooks from running
* Fix bug that prevented RailsSchemaUpToDate from working in directories that
  contained decimals
* Warn when trying to pipe commands using the `execute` helper, as this is not
  supported
* Include both standard out/error streams in exception messages in pre-commit
  hook context

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
  ran them. See [Security](README.md#security) for more information
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
  [haml-lint](https://github.com/brigade/haml-lint)

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
