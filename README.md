[![Gem Version](https://badge.fury.io/rb/overcommit.svg)](https://badge.fury.io/rb/overcommit)
[![Build Status](https://github.com/sds/overcommit/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/sds/overcommit/actions/workflows/tests.yml/badge.svg?branch=main)
[![Coverage Status](https://coveralls.io/repos/github/sds/overcommit/badge.svg?branch=main)](https://coveralls.io/github/sds/overcommit?branch=main)
[![Inline docs](http://inch-ci.org/github/sds/overcommit.svg?branch=main)](http://inch-ci.org/github/sds/overcommit)

<p align="center">
  <img width="65%" alt="Overcommit Logo" src="https://github.com/user-attachments/assets/b0d31df7-1d86-4e09-9c48-c96955e0713e" />
  <br />
  <em>A tool to manage and configure</em>
<a href="http://git-scm.com/book/en/Customizing-Git-Git-Hooks">Git hooks</a>
</p>

In addition to supporting a wide variety of hooks that can be used across
multiple repositories, you can also define hooks specific to a repository which
are stored in source control. You can also easily
[add your existing hook scripts](#adding-existing-git-hooks) or
[use some of your existing line-oriented analysis tools](#adding-existing-line-aware-commands) without writing
any Ruby code.

- [Requirements](#requirements)
  - [Windows](#windows)
  - [Dependencies](#dependencies)
- [Installation](#installation)
  - [Automatically Install Overcommit Hooks](#automatically-install-overcommit-hooks)
- [Usage](#usage)
  - [Skipping Hooks](#skipping-hooks)
  - [Disabling all default hooks](#disabling-all-default-hooks)
  - [Disabling Overcommit](#disabling-overcommit)
  - [Disabling Colorized Output](#disabling-colorized-output)
- [Continuous Integration](#continuous-integration)
- [Configuration](#configuration)
  - [Hook Options](#hook-options)
  - [Hook Categories](#hook-categories)
    - [The `ALL` Hook](#the-all-hook)
  - [Gemfile](#gemfile)
  - [Plugin Directory](#plugin-directory)
  - [Gem Plugins](#gem-plugins)
  - [Quiet Hook Runs](#quiet-hook-runs)
  - [Concurrency](#concurrency)
  - [Signature Verification](#signature-verification)
- [Built-In Hooks](#built-in-hooks)
  - [CommitMsg](#commitmsg)
  - [PostCheckout](#postcheckout)
  - [PostCommit](#postcommit)
  - [PostMerge](#postmerge)
  - [PostRewrite](#postrewrite)
  - [PreCommit](#precommit)
    - [WARNING: pre-commit hooks cannot have side effects](#warning-pre-commit-hooks-cannot-have-side-effects)
  - [PrePush](#prepush)
  - [PreRebase](#prerebase)
- [Repo-Specific hooks](#repo-specific-hooks)
  - [Adding Existing Git Hooks](#adding-existing-git-hooks)
  - [Adding Existing Line-Aware Commands](#adding-existing-line-aware-commands)
- [Security](#security)
  - [Disabling Signature Checking](#disabling-signature-checking)
- [Contributing](#contributing)
- [Community](#community)
- [Changelog](#changelog)
- [License](#license)

## Requirements

This project aims to support the following Ruby runtimes on \*nix (and best effort on Windows):

* Ruby 2.6+

### Dependencies

Some hooks have third-party dependencies. For example, to lint your
[SCSS](http://sass-lang.com/) files, you're going to need the
[scss_lint gem](https://github.com/sds/scss-lint).

Depending on the hooks you enable/disable for your repository, you'll need to
ensure your development environment already has those dependencies installed.
Most hooks will display a warning if a required executable isn't available.

If you are using Bundler to manage your Ruby gem dependencies, you'll likely
want to use the [`gemfile`](#gemfile) option to control which gem versions are
available during your hook runs.

## Installation

`overcommit` is installed via [RubyGems](https://rubygems.org/). It is strongly
recommended that your environment support running `gem install` without
requiring root user privileges via `sudo` or otherwise. Using a Ruby version
manager like [`rbenv`](https://github.com/rbenv/rbenv/) or
[`rvm`](https://rvm.io/) is recommended.

Once you have an environment that allows you to install gems without `sudo`,
run:

```bash
gem install overcommit
```

You can then run the `overcommit` command to install hooks into repositories.

```bash
mkdir important-project
cd important-project
git init
overcommit --install
```

After running `overcommit --install`, any existing hooks for your repository
which Overcommit will replace will be backed up. You can restore everything to
the way it was by running `overcommit --uninstall`.

### Automatically Install Overcommit Hooks

If you want to use `overcommit` for all repositories you create/clone going
forward, add the following to automatically run in your shell environment:

```bash
export GIT_TEMPLATE_DIR="$(overcommit --template-dir)"
```

The `GIT_TEMPLATE_DIR` provides a directory for Git to use as a template
for automatically populating the `.git` directory. If you have your own
template directory, you might just want to copy the contents of
`overcommit --template-dir` to that directory.

## Usage

Once you've installed the hooks via `overcommit --install`, they will
automatically run when the appropriate hook is triggered.

The `overcommit` executable supports the following command-line flags:

Command Line Flag         | Description
--------------------------|----------------------------------------------------
`-i`/`--install`          | Install Overcommit hooks in a repository
`-u`/`--uninstall`        | Remove Overcommit hooks from a repository
`-f`/`--force`            | Don't bail on install if other hooks already exist--overwrite them
`-l`/`--list-hooks`       | Display all available hooks in the current repository
`-r`/`--run`              | Run pre-commit hook against all tracked files in repository
`--diff <ref>`            | Run pre-commit hook against all changed files relative to `<ref>`
`-t`/`--template-dir`     | Print location of template directory
`-h`/`--help`             | Show command-line flag documentation
`-v`/`--version`          | Show version

### Skipping Hooks

Sometimes a hook will report an error that for one reason or another you'll want
to ignore. To prevent these errors from blocking your commit, you can include
the name of the relevant hook in the `SKIP` environment variable, e.g.

```bash
SKIP=RuboCop git commit
```

If you would prefer to specify a whitelist of hooks rather than a blacklist, use
the `ONLY` environment variable instead.

```bash
ONLY=RuboCop git commit
```

Use this feature sparingly, as there is no point to having the hook in the first
place if you're just going to ignore it. If you want to ensure a hook is never
skipped, set the `required` option to `true` in its configuration. If you
attempt to skip it, you'll see a warning telling you that the hook is required,
and the hook will still run.

### Disabling all default hooks

For each hook type, use the special `ALL` hook to disable all hooks by default.

```yaml
CommitMsg:
  ALL:
    enabled: false
```

### Disabling Overcommit

If you have scripts that execute `git` commands where you don't want Overcommit
hooks to run, you can disable Overcommit entirely by setting the
`OVERCOMMIT_DISABLE` environment variable.

```bash
OVERCOMMIT_DISABLE=1 ./my-custom-script
```

### Disabling Colorized Output

Overcommit automatically colorizes its output based on whether it is outputting
to a TTY. However, you can manually enable/disable color by setting the
`OVERCOMMIT_COLOR` environment variable.

```bash
OVERCOMMIT_COLOR=0 git commit
```

## Continuous Integration

You can run the same set of hooks that would be executed in a pre-commit hook
against your entire repository by running `overcommit --run`. This makes it
easy to have the checks verified by a CI service such as
[Travis CI](https://travis-ci.com/), including custom hooks you've written
yourself.

The `--run` flag works by creating a pre-commit context that assumes _all_ the
files in your repository have changed, and follows the same rules as a normal
pre-commit check. If any hook fails with an error, it will return a non-zero
exit code.

## Configuration

Overcommit provides a flexible configuration system that allows you to tailor
the built-in hooks to suit your workflow. All configuration specific to a
repository is stored in `.overcommit.yml` in the top-level directory of the
repository.

When writing your own configuration, it will automatically extend the
[default configuration](config/default.yml), so you only need to specify
your configuration with respect to the default. In order to
enable/disable hooks, you can add the following to your repo-specific
configuration file:

```yaml
PreCommit:
  RuboCop:
    enabled: true
    command: ['bundle', 'exec', 'rubocop'] # Invoke within Bundler context
```

Additionally, you may wish to have repo-specific configurations that are local to your computer that are not part of the shared repo config.
Adding a `.local-overcommit.yml` file in the top-level directory of the repository adds another configuration file. This file works the same as `.overcommit.yml`.
Adding this to ignored files in a git repo will allow you to have a local configuration per repo.

### Hook Options

Individual hooks expose both built-in configuration options as well as their
own custom options unique to each hook. The following table lists all built-in
configuration options:

Option                                  | Description
----------------------------------------|--------------------------------------
`enabled`                               | If `false`, this hook will never be run
`required`                              | If `true`, this hook cannot be skipped via the `SKIP` environment variable
`quiet`                                 | If `true`, this hook does not display any output unless it warns/fails
`description`                           | Message displayed while hook is running.
`requires_files`                        | If `true`, this hook runs only if files that are applicable to it have been modified. See `include` and `exclude` for how to specify applicable files.
`include`                               | File paths or glob patterns of files that apply to this hook. The hook will only run on the applicable files when they have been modified. Note that the concept of modified varies for different types of hooks. By default, `include` matches every file until you specify a list of patterns.
`exclude`                               | File paths or glob patterns of files that do not apply to this hook. This is used to exclude any files that would have been matched by `include`.
`exclude_branches`                      | List of branch names or glob patterns of branches that this hook should not run against.
`exclude_remotes`                       | *`PrePush` hooks only.* List of remote names that the hook should not run against.
`include_remote_ref_deletions`          | *`PrePush` hooks only.* By default, `PrePush` hooks will **not** run for pushes that delete a remote ref (i.e. branches or tags). Set to `true` to have the hook run even for deleted remote ref.
`problem_on_unmodified_line`            | How to treat errors reported on lines that weren't modified during the action captured by this hook (e.g. for pre-commit hooks, warnings/errors reported on lines that were not staged with `git add` may not be warnings/errors you care about). Valid values are `report`: report errors/warnings as-is regardless of line location (default); `warn`: report errors as warnings if they are on lines you didn't modify; and `ignore`: don't display errors/warnings at all if they are on lines you didn't modify (`ignore` is _not_ recommended).
`on_fail`                               | Change the status of a failed hook to `warn` or `pass`. This allows you to treat failures as warnings or potentially ignore them entirely, but you should use caution when doing so as you might be hiding important information.
`on_warn`                               | Similar to `on_fail`, change the status of a hook that returns a warning status to either `pass` (you wish to silence warnings entirely) or `fail` (you wish to treat all warnings as errors).
`required_executable`                   | Name of an executable that must exist in order for the hook to run. If this is a path (e.g. `./bin/ruby`), ensures that the executable file exists at the given location relative to the repository root. Otherwise, if it just the name of an executable (e.g. `ruby`) checks if the executable can be found in one of the directories in the `PATH` environment variable. Set this to a specific path if you want to always use an executable that is stored in your repository. (e.g. RubyGems bin stubs, Node.js binaries, etc.)
`required_library`/`required_libraries` | List of Ruby libraries to load with `Kernel.require` before the hook runs. This is specifically for hooks that integrate with external Ruby libraries.
`command`                               | Array of arguments to use as the command. How each hook uses this is different, but it allows hooks to change the context with which they run. For example, you can change the command to be `['bundle', 'exec', 'rubocop']` instead of just `rubocop` so that you can use the gem versions specified in your local `Gemfile.lock`. This defaults to the name of the `required_executable`.
`flags`                                 | Array of arguments to append to the `command`. This is useful for customizing the behavior of a tool. It's also useful when a newer version of a tool removes/renames existing flags, so you can update the flags via your `.overcommit.yml` instead of waiting for an upstream fix in Overcommit.
`env`                                   | Hash of environment variables the hook should be run with. This is intended to be used as a last resort when an executable a hook runs is configured only via an environment variable. Any pre-existing environment variables with the same names as ones defined in `env` will have their original values restored after the hook runs. **NOTE:** Currently, only strings are accepted values. Boolean values will raise an error. **WARNING**: If you set the same environment variable for multiple hooks and you've enabled parallel hook runs, since the environment is shared across all threads you could accidentally have these separate hooks trample on each other. In this case, you should disable parallelization for the hook using the `parallelize` option.
`parallelize`                           | Whether to allow this hook to be run concurrently with other hooks. Disable this if the hook requires access to a shared resource that other hooks may also access and modify (e.g. files, the git index, process environment variables, etc).
`processors`                            | The number of processing units to reserve for this hook. This does not reserve CPUs, but indicates that out of the total number of possible concurrent hooks allowed by the global `concurrency` option, this hook requires the specified number. Thus in the typical case where `concurrency` is set to the number of available cores (default), and you have a hook that executes an application which itself creates 2 threads (or is otherwise scheduled on 2 cores), you can indicate that Overcommit should allocate 2 `processors` to the hook. Ideally this means your hooks won't put undue load on your available cores.
`install_command`                       | Command the user can run to install the `required_executable` (or alternately the specified `required_libraries`). This is intended for documentation purposes, as Overcommit does not install software on your behalf since there are too many edge cases where such behavior would result in incorrectly configured installations (e.g. installing a Python package in the global package space instead of in a virtual environment).
`skip_file_checkout`                    | Whether to skip this hook for file checkouts (e.g. `git checkout some-ref -- file`). Only applicable to `PostCheckout` hooks.
`skip_if`                               | Array of arguments to be executed to determine whether or not the hook should run. For example, setting this to a value of `['bash', '-c', '! which my-executable']` would allow you to skip running this hook if `my-executable` was not in the bin path.
`message_pattern`                       | Regex used to parse diagnostics from [line-aware command hooks](#adding-existing-line-aware-commands). Requires a named `file` capture; optional `line` and `type` captures provide line handling and warning classification.
`warning_message_type_pattern`          | Optional regex (or literal substring) identifying warnings in the `type` capture of a line-aware command hook. All other diagnostics are errors.

In addition to the built-in configuration options, each hook can expose its
own unique configuration options. The `AuthorEmail` hook, for example, allows
you to customize the regex used to check commit author emails via the `pattern`
option&mdash;useful if you want to enforce that developers use a company
email address for their commits. This provides incredible flexibility for hook
authors as you can make your hooks sufficiently generic and then customize them
on a per-project basis.

### Hook Categories

Hook configurations are organized into categories based on the type of hook. So
`pre-commit` hooks are located under the `PreCommit` option, and `post-commit`
hooks are located under `PostCommit`. See the
[default configuration](config/default.yml) for a thorough example.

#### The `ALL` Hook

Within a hook category, there is a special type of hook configuration that
applies to _all_ hooks in the category. This configuration looks like a normal
hook configuration, except it has the name `ALL`:

```yaml
PreCommit:
  ALL:
    problem_on_unmodified_line: warn
    requires_files: true
    required: false
    quiet: false

  SomeHook:
    enabled: true

  ...
```

The `ALL` configuration is useful for when you want to
[DRY](http://en.wikipedia.org/wiki/Don%27t_repeat_yourself) up your
configuration, or when you want to apply changes across an entire category of
hooks.

Note that array configuration options (like `include`/`exclude`) in the
special `ALL` hook section are not merged with individual hook configurations
if custom ones are defined for the hook.
Any custom configuration option for `include`/`exclude` will replace the `ALL`
hook's configuration. If you want to have a global list of default exclusions
and extend them with a custom list, you can use YAML references, e.g.

```yaml
PreCommit:
  ALL:
    exclude: &default_excludes
      - 'node_modules/**/*'
      - 'vendor/**/*'
  MyHook:
    exclude:
      - *default_excludes
      - 'another/directory/in/addition/to/default/excludes/**/*'
```

Again, you can consult the [default configuration](config/default.yml) for
detailed examples of how the `ALL` hook can be used.

### Gemfile

You may want to enforce the version of Overcommit or other gems that you use in
your git hooks. This can be done by specifying the `gemfile` option in your
`.overcommit.yml`.

The `gemfile` option tells Overcommit to load the specified file with
[Bundler](http://bundler.io/), the standard gem dependency manager for Ruby.
This is useful if you would like to:

  - Enforce a specific version of Overcommit to use for all hook runs
    (or to use a version from the master branch that has not been released yet)
  - Enforce a specific version or unreleased branch is used for a gem you want
    to use in your git hooks

Loading a Bundler context necessarily adds a startup delay to your hook runs
as Bundler parses the specified `Gemfile` and checks that the dependencies are
satisfied. Thus for projects with many gems this can introduce a noticeable
delay.

The recommended workaround is to create a separate `Gemfile` in the root of
your repository (call it `.overcommit_gems.rb`), and include only the gems that
your Overcommit hooks need in order to run. Generate the associated lock file
by running:

```bash
bundle install --gemfile=.overcommit_gems.rb
```

...and commit `.overcommit_gems.rb` and the resulting
`.overcommit_gems.rb.lock` file to your repository. Set your `gemfile` option
to `.overcommit_gems.rb`, and you're all set.

Using a smaller Gemfile containing only the gems used by your Overcommit hooks
significantly reduces the startup delay in your hook runs. It is thus the
recommended approach unless your project has a relatively small number of gems
in your `Gemfile`.

When using your application's `Gemfile`, a checkout or pull can introduce a
`Gemfile.lock` that requires gems you have not installed yet. Overcommit cannot
load that bundle, so even `post-checkout` hooks fail with a message such as
`Problem loading 'Gemfile': Could not find ...`. The checkout has already changed
your working tree when this happens. During a rebase, a hook error can interrupt
the operation and leave you with a detached HEAD.

To prevent this, install the updated branch's dependencies before rebasing onto
it, or use the separate hook Gemfile described above so application dependency
updates do not prevent Overcommit from loading.

If a rebase is interrupted by missing gems:

1. Run `bundle install --gemfile=Gemfile` (using the path configured in `gemfile`).
2. Run `git status` to check whether a rebase is in progress. If it is, run
   `git rebase --abort` to return to your original branch, then retry the rebase.
   Restarting also handles a failed commit hook leaving a partly replayed commit.
3. If Git reports no rebase in progress but HEAD is detached, switch back to
   your original branch and retry the rebase after installing the updated
   branch's dependencies.

To abandon an in-progress rebase when missing dependencies prevent hooks from
loading, run `OVERCOMMIT_DISABLE=1 git rebase --abort`. This disables Overcommit
for that command. Once dependencies are installed, normal hook runs resume.

### Plugin Directory

You can change the directory that project-specific hooks are loaded from via
the `plugin_directory` option. The default directory is `.git-hooks`.

### Gem Plugins

Install a hook gem (include it in your Gemfile when using Bundler), then declare
its namespace and enable its hooks:

```yaml
gem_plugins:
  Company: overcommit-company
PreCommit:
  Company::MyHook:
    enabled: true
```

Gems provide `lib/overcommit/hooks/pre_commit/my_hook.rb`, defining
`Overcommit::Hook::PreCommit::Company::MyHook` as a subclass of
`Overcommit::Hook::PreCommit::Base`; use `require_relative` for helpers.
Namespaces keep gem hooks separate from built-in and repository hooks.
No gems load unless declared and enabled. After reviewing changes, run
`overcommit --sign` and `overcommit --sign pre-commit` (or the relevant hook type).
Approvals cover gem contents, runtime dependencies, and hook configuration;
changes require approval again when signature verification is enabled.
Gem entrypoints are not automatically required, and symlinks are unsupported.

### Quiet Hook Runs

If you prefer to have your hooks be completely silent unless there is a
problem, you can set the top-level `quiet` option to `true`. Note that if you
have many hooks or slow hooks this may not be desirable, as you don't get
visual feedback indicating the general progress of the hook run.

### Concurrency

Overcommit runs hooks in parallel by default, with a number of concurrent
workers equal to the number of logical cores on your machine. If you know your
particular set of hooks would benefit from higher/lower number of workers, you
can adjust the global `concurrency` option. You can define single-operator
mathematical expressions, e.g. `%{processors} * 2`, or `%{processors} / 2`.

```yaml
concurrency: '%{processors} / 4'
```

Note that individual hooks can specify the number of processors they require
with the `processors` hook option. See the [hook options](#hook-options)
section for more details.

### Signature Verification

You can disable manual verification of signatures by setting
`verify_signatures` to `false`. See the [Security](#security) section for more
information on this option and what exactly it controls.

## Built-In Hooks

Currently, Overcommit supports the following hooks out of the box&mdash;simply
enable them in your `.overcommit.yml`.

Hook names are case-sensitive. For example, use `KtLint` to enable the built-in
Kotlin hook, which passes only the applicable modified files to `ktlint`:

```yaml
PreCommit:
  KtLint:
    enabled: true
```

Using `Ktlint` with a `required_executable: ktlint` setting instead defines an
[ad hoc hook](#adding-existing-git-hooks). Ad hoc hooks receive Git's original
hook arguments, so this runs `ktlint` without filenames and lets it check its
default file patterns, including unmodified files.

**Note**: Hooks with a `*` are enabled by default.

**Warning**: This list represents the list of hooks available on the `master`
branch. Please consult the [change log](CHANGELOG.md) to view which hooks have
not been released yet.

### CommitMsg

`commit-msg` hooks are run against every commit message you write before a
commit is created. A failed hook prevents a commit from being created. These
hooks are useful for enforcing policies on your commit messages, e.g. ensuring
a task ID is included for tracking purposes, or ensuring your commit messages
follow [proper formatting guidelines](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).

* [`*`CapitalizedSubject](lib/overcommit/hook/commit_msg/capitalized_subject.rb)
* [`*`EmptyMessage](lib/overcommit/hook/commit_msg/empty_message.rb)
* [GerritChangeId](lib/overcommit/hook/commit_msg/gerrit_change_id.rb)
* [HardTabs](lib/overcommit/hook/commit_msg/hard_tabs.rb)
* [MessageFormat](lib/overcommit/hook/commit_msg/message_format.rb)
* [RussianNovel](lib/overcommit/hook/commit_msg/russian_novel.rb)
* [`*`SingleLineSubject](lib/overcommit/hook/commit_msg/single_line_subject.rb)
* [SpellCheck](lib/overcommit/hook/commit_msg/spell_check.rb)
* [`*`TextWidth](lib/overcommit/hook/commit_msg/text_width.rb)
* [`*`TrailingPeriod](lib/overcommit/hook/commit_msg/trailing_period.rb)

### PostCheckout

`post-checkout` hooks run after a successful `git checkout`, or in other words
any time your `HEAD` changes or a file is explicitly checked out.

* [BowerInstall](lib/overcommit/hook/post_checkout/bower_install.rb)
* [BundleInstall](lib/overcommit/hook/post_checkout/bundle_install.rb)
* [ComposerInstall](lib/overcommit/hook/post_checkout/composer_install.rb)
* [IndexTags](lib/overcommit/hook/post_checkout/index_tags.rb)
* [NpmInstall](lib/overcommit/hook/post_checkout/npm_install.rb)
* [SubmoduleStatus](lib/overcommit/hook/post_checkout/submodule_status.rb)
* [YarnInstall](lib/overcommit/hook/post_checkout/yarn_install.rb)

### PostCommit

`post-commit` hooks run after a commit is successfully created. A hook failing
in this case does not prevent the commit since it has already occurred;
however, it can be used to alert the user to some issue.

* [BowerInstall](lib/overcommit/hook/post_commit/bower_install.rb)
* [BundleInstall](lib/overcommit/hook/post_commit/bundle_install.rb)
* [Commitplease](lib/overcommit/hook/post_commit/commitplease.rb)
* [ComposerInstall](lib/overcommit/hook/post_commit/composer_install.rb)
* [GitGuilt](lib/overcommit/hook/post_commit/git_guilt.rb)
* [IndexTags](lib/overcommit/hook/post_commit/index_tags.rb)
* [NpmInstall](lib/overcommit/hook/post_commit/npm_install.rb)
* [SubmoduleStatus](lib/overcommit/hook/post_commit/submodule_status.rb)
* [YarnInstall](lib/overcommit/hook/post_commit/yarn_install.rb)

### PostMerge

`post-merge` hooks run after a `git merge` executes successfully with no merge
conflicts. A hook failing in this case does not prevent the merge since it has
already occurred; however, it can be used to alert the user to some issue.

* [BowerInstall](lib/overcommit/hook/post_merge/bower_install.rb)
* [BundleInstall](lib/overcommit/hook/post_merge/bundle_install.rb)
* [ComposerInstall](lib/overcommit/hook/post_merge/composer_install.rb)
* [IndexTags](lib/overcommit/hook/post_merge/index_tags.rb)
* [NpmInstall](lib/overcommit/hook/post_merge/npm_install.rb)
* [SubmoduleStatus](lib/overcommit/hook/post_merge/submodule_status.rb)
* [YarnInstall](lib/overcommit/hook/post_merge/yarn_install.rb)

### PostRewrite

`post-rewrite` hooks run after a commit is modified by a `git commit --amend`
or `git rebase`. A hook failing in this case does not prevent the rewrite since
it has already occurred; however, it can be used to alert the user to some
issue.

* [BowerInstall](lib/overcommit/hook/post_rewrite/bower_install.rb)
* [BundleInstall](lib/overcommit/hook/post_rewrite/bundle_install.rb)
* [ComposerInstall](lib/overcommit/hook/post_rewrite/composer_install.rb)
* [IndexTags](lib/overcommit/hook/post_rewrite/index_tags.rb)
* [NpmInstall](lib/overcommit/hook/post_rewrite/npm_install.rb)
* [SubmoduleStatus](lib/overcommit/hook/post_rewrite/submodule_status.rb)
* [YarnInstall](lib/overcommit/hook/post_rewrite/yarn_install.rb)

### PreCommit

`pre-commit` hooks are run after `git commit` is executed, but before the
commit message editor is displayed. If a hook fails, the commit will not be
created. These hooks are ideal for syntax checkers, linters, and other checks
that you want to run before you allow a commit to even be created.

#### WARNING: pre-commit hooks cannot have side effects

`pre-commit` hooks currently do not support hooks with side effects (such as
modifying files and adding them to the index with `git add`). This is a
consequence of Overcommit's pre-commit hook stashing behavior to ensure hooks
are run against _only the changes you are about to commit_.

Without Overcommit, the proper way to write a `pre-commit` hook would be to
extract the staged changes into temporary files and lint those files
instead of whatever contents are in your working tree (as you don't want
unstaged changes to taint your results). Overcommit takes care
of this for you, but to do it in a generalized way introduces this
limitation. See the [thread tracking this
issue](https://github.com/sds/overcommit/issues/238) for more details.

* [`*`AuthorEmail](lib/overcommit/hook/pre_commit/author_email.rb)
* [`*`AuthorName](lib/overcommit/hook/pre_commit/author_name.rb)
* [BerksfileCheck](lib/overcommit/hook/pre_commit/berksfile_check.rb)
* [`*`BrokenSymlinks](lib/overcommit/hook/pre_commit/broken_symlinks.rb)
* [BundleAudit](lib/overcommit/hook/pre_commit/bundle_audit.rb)
* [BundleCheck](lib/overcommit/hook/pre_commit/bundle_check.rb)
* [BundleOutdated](lib/overcommit/hook/pre_commit/bundle_outdated.rb)
* [`*`CaseConflicts](lib/overcommit/hook/pre_commit/case_conflicts.rb)
* [ChamberSecurity](lib/overcommit/hook/pre_commit/chamber_security.rb)
* [CodeSpellCheck](lib/overcommit/hook/pre_commit/code_spell_check.rb)
* [CoffeeLint](lib/overcommit/hook/pre_commit/coffee_lint.rb)
* [Credo](lib/overcommit/hook/pre_commit/credo.rb)
* [CssLint](lib/overcommit/hook/pre_commit/css_lint.rb)
* [DartAnalyzer](lib/overcommit/hook/pre_commit/dart_analyzer.rb)
* [Dogma](lib/overcommit/hook/pre_commit/dogma.rb)
* [ErbLint](lib/overcommit/hook/pre_commit/erb_lint.rb)
* [EsLint](lib/overcommit/hook/pre_commit/es_lint.rb)
* [ExecutePermissions](lib/overcommit/hook/pre_commit/execute_permissions.rb)
* [Fasterer](lib/overcommit/hook/pre_commit/fasterer.rb)
* [FileSize](lib/overcommit/hook/pre_commit/file_size.rb)
* [FixMe](lib/overcommit/hook/pre_commit/fix_me.rb)
* [Flay](lib/overcommit/hook/pre_commit/flay.rb)
* [Foodcritic](lib/overcommit/hook/pre_commit/foodcritic.rb)
* [ForbiddenBranches](lib/overcommit/hook/pre_commit/forbidden_branches.rb)
* [GoLint](lib/overcommit/hook/pre_commit/go_lint.rb)
* [GoVet](lib/overcommit/hook/pre_commit/go_vet.rb)
* [Hadolint](lib/overcommit/hook/pre_commit/hadolint.rb)
* [LicenseFinder](lib/overcommit/hook/pre_commit/license_finder.rb)
* [HamlLint](lib/overcommit/hook/pre_commit/haml_lint.rb)
* [HardTabs](lib/overcommit/hook/pre_commit/hard_tabs.rb)
* [HerbLint](lib/overcommit/hook/pre_commit/herb_lint.rb)
* [Hlint](lib/overcommit/hook/pre_commit/hlint.rb)
* [HtmlHint](lib/overcommit/hook/pre_commit/html_hint.rb)
* [HtmlTidy](lib/overcommit/hook/pre_commit/html_tidy.rb)
* [ImageOptim](lib/overcommit/hook/pre_commit/image_optim.rb)
* [JavaCheckstyle](lib/overcommit/hook/pre_commit/java_checkstyle.rb)
* [Jscs](lib/overcommit/hook/pre_commit/jscs.rb)
* [JsHint](lib/overcommit/hook/pre_commit/js_hint.rb)
* [JsLint](lib/overcommit/hook/pre_commit/js_lint.rb)
* [Jsl](lib/overcommit/hook/pre_commit/jsl.rb)
* [JsonSyntax](lib/overcommit/hook/pre_commit/json_syntax.rb)
* [KtLint](lib/overcommit/hook/pre_commit/kt_lint.rb)
* [LicenseHeader](lib/overcommit/hook/pre_commit/license_header.rb)
* [LineEndings](lib/overcommit/hook/pre_commit/line_endings.rb)
* [LocalPathsInGemfile](lib/overcommit/hook/pre_commit/local_paths_in_gemfile.rb)
* [Mdl](lib/overcommit/hook/pre_commit/mdl.rb)
* [`*`MergeConflicts](lib/overcommit/hook/pre_commit/merge_conflicts.rb)
* [NginxTest](lib/overcommit/hook/pre_commit/nginx_test.rb)
* [OxFmt](lib/overcommit/hook/pre_commit/ox_fmt.rb)
* [OxLint](lib/overcommit/hook/pre_commit/ox_lint.rb)
* [PhpCs](lib/overcommit/hook/pre_commit/php_cs.rb)
* [PhpCsFixer](lib/overcommit/hook/pre_commit/php_cs_fixer.rb)
* [PhpLint](lib/overcommit/hook/pre_commit/php_lint.rb)
* [PhpStan](lib/overcommit/hook/pre_commit/php_stan.rb)
* [Pronto](lib/overcommit/hook/pre_commit/pronto.rb)
* [PuppetLint](lib/overcommit/hook/pre_commit/puppet_lint.rb)
* [PuppetMetadataJsonLint](lib/overcommit/hook/pre_commit/puppet_metadata_json_lint.rb)
* [Pycodestyle](lib/overcommit/hook/pre_commit/pycodestyle.rb)
* [Pydocstyle](lib/overcommit/hook/pre_commit/pydocstyle.rb)
* [Pyflakes](lib/overcommit/hook/pre_commit/pyflakes.rb)
* [Pylint](lib/overcommit/hook/pre_commit/pylint.rb)
* [PythonFlake8](lib/overcommit/hook/pre_commit/python_flake8.rb)
* [RakeTarget](lib/overcommit/hook/pre_commit/rake_target.rb)
* [RailsBestPractices](lib/overcommit/hook/pre_commit/rails_best_practices.rb)
* [RailsSchemaUpToDate](lib/overcommit/hook/pre_commit/rails_schema_up_to_date.rb)
* [Reek](lib/overcommit/hook/pre_commit/reek.rb)
* [RuboCop](lib/overcommit/hook/pre_commit/rubo_cop.rb)
* [RubyLint](lib/overcommit/hook/pre_commit/ruby_lint.rb)
* [RubySyntax](lib/overcommit/hook/pre_commit/ruby_syntax.rb)
* [SwiftLint](lib/overcommit/hook/pre_commit/swift_lint.rb)
* [Scalariform](lib/overcommit/hook/pre_commit/scalariform.rb)
* [Scalastyle](lib/overcommit/hook/pre_commit/scalastyle.rb)
* [ScssLint](lib/overcommit/hook/pre_commit/scss_lint.rb)
* [SemiStandard](lib/overcommit/hook/pre_commit/semi_standard.rb)
* [ShellCheck](lib/overcommit/hook/pre_commit/shell_check.rb)
* [SlimLint](lib/overcommit/hook/pre_commit/slim_lint.rb)
* [Sorbet](lib/overcommit/hook/pre_commit/sorbet.rb)
* [Sqlint](lib/overcommit/hook/pre_commit/sqlint.rb)
* [Standard](lib/overcommit/hook/pre_commit/standard.rb)
* [Stylelint](lib/overcommit/hook/pre_commit/stylelint.rb)
* [TrailingWhitespace](lib/overcommit/hook/pre_commit/trailing_whitespace.rb)
* [TravisLint](lib/overcommit/hook/pre_commit/travis_lint.rb)
* [TsLint](lib/overcommit/hook/pre_commit/ts_lint.rb)
* [Vale](#vale)
* [Vint](lib/overcommit/hook/pre_commit/vint.rb)
* [W3cCss](lib/overcommit/hook/pre_commit/w3c_css.rb)
* [W3cHtml](lib/overcommit/hook/pre_commit/w3c_html.rb)
* [XmlLint](lib/overcommit/hook/pre_commit/xml_lint.rb)
* [XmlSyntax](lib/overcommit/hook/pre_commit/xml_syntax.rb)
* [YamlLint](lib/overcommit/hook/pre_commit/yaml_lint.rb)
* [YamlSyntax](lib/overcommit/hook/pre_commit/yaml_syntax.rb)
* [YardCoverage](lib/overcommit/hook/pre_commit/yard_coverage.rb)
* [YarnCheck](lib/overcommit/hook/pre_commit/yarn_check.rb)

#### Vale

[Vale](https://vale.sh/) checks spelling and style in text, markup, and source
files. Install Vale using its [installation instructions](https://vale.sh/docs/install),
then add a `.vale.ini` and any styles your project needs. Enable the hook in
`.overcommit.yml`:

```yaml
PreCommit:
  Vale:
    enabled: true
```

Vale uses a [line-aware command hook](#adding-existing-line-aware-commands)
configured in [config/default.yml](config/default.yml), so no Ruby plugin is
needed. It receives matching staged files and runs `vale --output=line`.
Use `include` and `exclude` to customize the file types and paths checked;
some formats require additional tools or Vale configuration.

The default line output does not include severity, so all diagnostics from a
failed Vale command are treated as errors. `problem_on_unmodified_line` controls
how diagnostics on unchanged lines are handled. To distinguish warnings, use a
[custom Vale output template](https://github.com/vale-cli/vale/issues/350)
and configure `flags`, `message_pattern`, and `warning_message_type_pattern`
as described in the line-aware command documentation.

### PrePush

`pre-push` hooks are run during `git push`, after remote refs have been updated
but before any objects have been transferred. If a hook fails, the push is
aborted.

* [Brakeman](lib/overcommit/hook/pre_push/brakeman.rb)
* [FlutterTest](lib/overcommit/hook/pre_push/flutter_test.rb)
* [Minitest](lib/overcommit/hook/pre_push/minitest.rb)
* [PhpUnit](lib/overcommit/hook/pre_push/php_unit.rb)
* [Pronto](lib/overcommit/hook/pre_push/pronto.rb)
* [ProtectedBranches](lib/overcommit/hook/pre_push/protected_branches.rb)
* [PubTest](lib/overcommit/hook/pre_push/pub_test.rb)
* [Pytest](lib/overcommit/hook/pre_push/pytest.rb)
* [PythonNose](lib/overcommit/hook/pre_push/python_nose.rb)
* [RakeTarget](lib/overcommit/hook/pre_push/rake_target.rb)
* [RSpec](lib/overcommit/hook/pre_push/r_spec.rb)
* [TestUnit](lib/overcommit/hook/pre_push/test_unit.rb)

### PreRebase

`pre-rebase` hooks are run during `git rebase`, before any commits are rebased.
If a hook fails, the rebase is aborted.

* [MergedCommits](lib/overcommit/hook/pre_rebase/merged_commits.rb)

## Repo-Specific hooks

Out of the box, `overcommit` comes with a set of hooks that enforce a variety of
styles and lints. However, some hooks only make sense in the context of a
specific repository.

For example, you can have a number of simple checks that run
against your code to catch common errors. For example, if you use
[RSpec](http://rspec.info/), you can make sure all spec files contain the
line `require 'spec_helper'`.

Inside our repository, we can add the file
`.git-hooks/pre_commit/ensure_spec_helper.rb` in order to automatically check
our spec files:

```ruby
module Overcommit::Hook::PreCommit
  class EnsureSpecHelper < Base
    def run
      errors = []

      applicable_files.each do |file|
        if File.read(file) !~ /^require 'spec_helper'/
          errors << "#{file}: missing `require 'spec_helper'`"
        end
      end

      return :fail, errors.join("\n") if errors.any?

      :pass
    end
  end
end
```

The corresponding configuration for this hook would look like:

```yaml
PreCommit:
  EnsureSpecHelper:
    enabled: true
    description: 'Checking for missing inclusion of spec_helper'
    include: '**/*_spec.rb'
```

### Adding Existing Git Hooks

You might already have hook scripts written which you'd like to integrate with
Overcommit right away. To make this easy, Overcommit allows you to include
your hook script in your configuration without writing any Ruby code.
For example:

```yaml
PostCheckout:
  CustomScript:
    enabled: true
    required_executable: './bin/custom-script'
```

So long as a command is given (either by specifying the `command` option
directly or specifying `required_executable`) a special hook is created that
executes the command and appends any arguments and standard input stream that
would have been passed to the regular hook. The hook passes or fails based
on the exit status of the command.

The script is executed as if Git were calling the hook directly. If you want
to understand which arguments are passed to the script depending on the type
of hook, see the [git-hooks documentation][GHD].

[GHD]: https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks

### Adding Existing Line-Aware Commands

Tools that report file diagnostics can use Overcommit's message handling without
writing a Ruby hook. Add a `message_pattern` regex to an existing command hook to
parse each line of its standard output. The command receives the applicable file
paths after its configured command and flags, instead of Git hook arguments or
standard input.

`message_pattern` is required to enable this behavior and has no default. It must
be a Ruby regex with a named `file` capture. An optional `line` capture enables
`problem_on_unmodified_line` handling. An optional `type` capture can be classified
using `warning_message_type_pattern`, which accepts a regex or a literal substring.
Without a matching warning type, diagnostics are errors. Other captures are ignored.

For example, to parse GNU/Emacs-style diagnostics such as
`file.rb:12: warning: unused variable`:

```yaml
PreCommit:
  CustomScript:
    enabled: true
    command: './bin/custom-script'
    include: '**/*.rb'
    message_pattern: !ruby/regexp /^(?<file>(?:\w:)?[^:]+):(?<line>\d+):[^ ]* (?<type>[^ ]+)/
    warning_message_type_pattern: !ruby/regexp /^warning:/i
```

The normal `include`, `exclude`, and `requires_files` options control which files
are passed to the command and whether it runs. `problem_on_unmodified_line`
controls how diagnostics on unchanged lines affect the result.

A successful command passes. For a failed command, the parsed diagnostics determine
whether the hook fails or warns. A failed command with no standard output still
fails and displays its standard error. Unexpected output that does not match
`message_pattern` raises a message processing error instead of being silently ignored.

Only standard output is parsed. For tools that write diagnostics to standard error,
use a wrapper script that redirects it with `2>&1`.

These options apply to command hooks without an existing built-in or repository
Ruby implementation. See the [Ruby regex documentation][RubyRE] for named captures.
To serialize a regex as YAML, use `require 'yaml'; puts YAML.dump(/MY-REGEXP/)` in
`irb` and omit the leading `---` from the result.

[RubyRE]: https://ruby-doc.org/core-2.7.3/Regexp.html

## Security

While Overcommit can make managing Git hooks easier and more convenient,
this convenience can come at a cost of being less secure.

Since installing Overcommit hooks will allow arbitrary plugin code in your
repository to be executed, you expose yourself to an attack where checking
out code from a third party can result in malicious code being executed
on your system.

As an example, consider the situation where you have an open source project.
An attacker could submit a pull request which adds a `post-checkout` hook
that executes some malicious code. When you fetch and checkout this pull
request, the `post-checkout` hook will be run on your machine, along with
the malicious code that you just checked out.

Overcommit stores signatures of configurations and hook plugin code you have
explicitly approved with `overcommit --sign` and `overcommit --sign <hook-type>`.
Unrecognized signatures trigger a warning so you can verify the changes before
running hooks. All previously approved signatures are remembered, so checking
out an older revision or rebasing through approved configurations does not
require signing them again.

A plugin's signature covers its source code together with its configuration.
Approving two versions does not approve other combinations of their code and
configuration.

Approvals are stored under `overcommit-signatures` in your repository's Git
directory, outside Git's object database. They cannot be committed, pushed, or
fetched, and Git garbage collection does not remove them. Each approval is a
small file at `<SHA256 of signature config key>/<SHA256 signature>`, so lookups
do not scan the history. The file contains the original config key (such as
`overcommit.configuration.signature` or `overcommit.PreCommit.MyHook.signature`)
and the approved signature, one per line. There is no history size limit.

To revoke one approval, delete its file. To revoke all approvals, delete the
`overcommit-signatures` directory. Run `overcommit --sign` and
`overcommit --sign <hook-type>` to approve the current versions again. Existing
signatures in local Git config migrate automatically on first use; their old
keys are removed so deleting approval files also revokes migrated signatures.

By default, linked [worktrees](https://git-scm.com/docs/git-worktree) share
history in their common Git directory. Enable `extensions.worktreeConfig`
(`git config extensions.worktreeConfig true`) to keep approvals and the
`verify_signatures` setting separate in each worktree's Git directory. Use
`git rev-parse --git-common-dir` to find shared storage, or
`git rev-parse --git-path overcommit-signatures` to find per-worktree storage.

### Disabling Signature Checking

In typical usage, your plugins usually don't change too often, so this warning
shouldn't become a nuisance. However, users who work within proprietary
repositories where all developers who can push changes to the repository
already have a minimum security clearance may wish to disable this check.

While not recommended, you can disable signature verification by setting
`verify_signatures` to `false` in your `.overcommit.yml` file.

**Regardless of whether you have `verify_signatures` disabled for your project,
if you are running Overcommit for the first time you will need to sign your
configuration with `overcommit --sign`**. This needs to happen once so
Overcommit can record in your local git repo's configuration (outside of source
control) that you intend to enable/disable verification. This way if someone
else changes `verify_signatures` you'll be asked to confirm the change.

## Contributing

We love contributions to Overcommit, be they bug reports, feature ideas, or
pull requests. See our [guidelines for contributing](CONTRIBUTING.md) to best
ensure your thoughts, ideas, or code get merged.

## Community

All major discussion surrounding Overcommit happens on the
[GitHub issues list](https://github.com/sds/overcommit/issues).

## Changelog

If you're interested in seeing the changes and bug fixes between each version
of `overcommit`, read the [Overcommit Changelog](CHANGELOG.md).

## License

This project is released under the [MIT license](MIT-LICENSE).

The Overcommit logo is adapted from the [Git Logo by Jason Long][GL], and
is licensed under the [Creative Commons Attribution 3.0 Unported License][CC3].

[GL]: https://git-scm.com/downloads/logos
[CC3]: http://creativecommons.org/licenses/by/3.0/
