[![Gem Version](https://badge.fury.io/rb/overcommit.svg)](https://badge.fury.io/rb/overcommit)
[![Build Status](https://travis-ci.org/brigade/overcommit.svg)](https://travis-ci.org/brigade/overcommit)
[![Coverage Status](https://coveralls.io/repos/brigade/overcommit/badge.svg)](https://coveralls.io/r/brigade/overcommit)
[![Code Climate](https://codeclimate.com/github/brigade/overcommit.png)](https://codeclimate.com/github/brigade/overcommit)
[![Dependency Status](https://gemnasium.com/brigade/overcommit.svg)](https://gemnasium.com/brigade/overcommit)
[![Inline docs](http://inch-ci.org/github/brigade/overcommit.svg?branch=master)](http://inch-ci.org/github/brigade/overcommit)

# Overcommit

`overcommit` is a tool to manage and configure
[Git hooks](http://git-scm.com/book/en/Customizing-Git-Git-Hooks).

![Demonstration](https://brigade.github.io/overcommit/overcommit.gif)

In addition to supporting a wide variety of hooks that can be used across
multiple repositories, you can also define hooks specific to a
repository (but unlike regular Git hooks, are stored in source control).

* [Requirements](#requirements)
  * [Dependencies](#dependencies)
* [Installation](#installation)
  * [Automatically Install Overcommit Hooks](#automatically-install-overcommit-hooks)
* [Usage](#usage)
* [Continuous Integration](#continuous-integration)
* [Configuration](#configuration)
  * [Hooks](#hooks)
  * [Hook Categories](#hook-categories)
  * [Plugin Directory](#plugin-directory)
  * [Signature Verification](#signature-verification)
* [Built-In Hooks](#built-in-hooks)
  * [CommitMsg](#commitmsg)
  * [PostCheckout](#postcheckout)
  * [PostCommit](#postcommit)
  * [PostMerge](#postmerge)
  * [PostRewrite](#postrewrite)
  * [PreCommit](#precommit)
  * [PrePush](#prepush)
  * [PreRebase](#prerebase)
* [Repo-Specific Hooks](#repo-specific-hooks)
* [Security](#security)
* [Contributing](#contributing)
* [Community](#community)
* [Changelog](#changelog)
* [License](#license)

## Requirements

This project aims to support the following Ruby runtimes:

* MRI 1.9.3 & 2.x
* JRuby 1.7.x
* Rubinius 2.x

### Dependencies

Some of the hooks have third-party dependencies. For example, to lint your
[SCSS](http://sass-lang.com/) files, you're going to need our
[scss-lint gem](https://github.com/brigade/scss-lint).

Depending on the hooks you enable/disable for your repository, you'll need to
ensure your development environment already has those dependencies installed.
Most hooks will display a warning if a required executable isn't available.

## Installation

`overcommit` is installed via [RubyGems](https://rubygems.org/):

```bash
gem install overcommit
```

You can then run the `overcommit` command to install hooks into repositories:

```bash
mkdir important-project
cd important-project
git init
overcommit --install
```

Any existing hooks for your repository which Overcommit would have replaced
will be backed up. You can restore everything to the way it was by running
`overcommit --uninstall`.

### Automatically Install Overcommit Hooks

If you want to use `overcommit` for all repositories you create/clone going
forward, add the following to automatically run in your shell environment:

```bash
export GIT_TEMPLATE_DIR=`overcommit --template-dir`
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

Use this feature sparingly, as there is no point to having the hook in the first
place if you're just going to ignore it. If you want to ensure a hook is never
skipped, set the `required` option to `true` in its configuration.

### Disabling Overcommit

If you have scripts that execute `git` commands where you don't want Overcommit
hooks to run, you can disable Overcommit entirely by setting the
`OVERCOMMIT_DISABLE` environment variable.

```bash
OVERCOMMIT_DISABLE=1 ./my-custom-script
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
`problem_on_unmodified_line`            | How to treat errors reported on lines that weren't modified during the action captured by this hook (e.g. for pre-commit hooks, warnings/errors reported on lines that were not staged with `git add` may not be warnings/errors you care about). Valid values are `report`: report errors/warnings as-is regardless of line location (default); `warn`: report errors as warnings if they are on lines you didn't modify; and `ignore`: don't display errors/warnings at all if they are on lines you didn't modify (`ignore` is _not_ recommended).
`on_fail`                               | Change the status of a failed hook to `warn` or `pass`. This allows you to treat failures as warnings or potentially ignore them entirely, but you should use caution when doing so as you might be hiding important information.
`on_warn`                               | Simliar to `on_fail`, change the status of a hook that returns a warning status to either `pass` (you wish to silence warnings entirely) or `fail` (you wish to treat all warnings as errors).
`required_executable`                   | Name of an executable that must exist in the `PATH` in order for the hook to run
`required_library`/`required_libraries` | List of Ruby libraries to load with `Kernel.require` before the hook runs. This is specifically for hooks that integrate with external Ruby libraries.
`command`                               | Array of arguments to use as the command. How each hook uses this is different, but it allows hooks to change the context with which they run. For example, you can change the command to be `['bundle', 'exec', 'rubocop']` instead of just `rubocop` so that you can use the gem versions specified in your local `Gemfile.lock`. This defaults to the name of the `required_executable`.
`flags`                                 | Array of arguments to append to the `command`. This is useful for customizing the behavior of a tool. It's also useful when a newer version of a tool removes/renames existing flags, so you can update the flags via your `.overcommit.yml` instead of waiting for an upstream fix in Overcommit.
`env`                                   | Hash of environment variables the hook should be run with. This is intended to be used as a last resort when an executable a hook runs is configured only via an environment variable. Any pre-existing environment variables with the same names as ones defined in `env` will have their original values restored after the hook runs.
`install_command`                       | Command the user can run to install the `required_executable` (or alternately the specified `required_libraries`). This is intended for documentation purposes, as Overcommit does not install software on your behalf since there are too many edge cases where such behavior would result in incorrectly configured installations (e.g. installing a Python package in the global package space instead of in a virtual environment).

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

Again, you can consult the [default configuration](config/default.yml) for
detailed examples of how the `ALL` hook can be used.

### Plugin Directory

You can change the directory that project-specific hooks are loaded from via
the `plugin_directory` option. The default directory is `.git-hooks`.

### Signature Verification

You can disable manual verification of plugin signatures by setting
`verify_plugin_signatures` to `false`. See the [Security](#security) section
for more information on this option and what exactly it controls.

## Built-In Hooks

Currently, Overcommit supports the following hooks out of the box&mdash;simply
enable them in your `.overcommit.yml`.

**Note**: Hooks with a `*` are enabled by default.

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
* [RussianNovel](lib/overcommit/hook/commit_msg/russian_novel.rb)
* [`*`SingleLineSubject](lib/overcommit/hook/commit_msg/single_line_subject.rb)
* [SpellCheck](lib/overcommit/hook/commit_msg/spell_check.rb)
* [`*`TextWidth](lib/overcommit/hook/commit_msg/text_width.rb)
* [`*`TrailingPeriod](lib/overcommit/hook/commit_msg/trailing_period.rb)

### PostCheckout

`post-checkout` hooks run after a successful `git checkout`, or in other words
any time your `HEAD` changes or a file is explicitly checked out.

* [IndexTags](lib/overcommit/hook/post_checkout/index_tags.rb)
* [SubmoduleStatus](lib/overcommit/hook/post_checkout/submodule_status.rb)

### PostCommit

`post-commit` hooks run after a commit is successfully created. A hook failing
in this case does not prevent the merge since it has already occurred; however,
it can be used to alert the user to some issue.

* [GitGuilt](lib/overcommit/hook/post_commit/git_guilt.rb)
* [IndexTags](lib/overcommit/hook/post_commit/index_tags.rb)
* [SubmoduleStatus](lib/overcommit/hook/post_commit/submodule_status.rb)

### PostMerge

`post-merge` hooks run after a `git merge` executes successfully with no merge
conflicts. A hook failing in this case does not prevent the merge since it has
already occurred; however, it can be used to alert the user to some issue.

* [IndexTags](lib/overcommit/hook/post_merge/index_tags.rb)
* [SubmoduleStatus](lib/overcommit/hook/post_merge/submodule_status.rb)

### PostRewrite

`post-rewrite` hooks run after a commit is modified by a `git commit --amend`
or `git rebase`. A hook failing in this case does not prevent the rewrite since
it has already occurred; however, it can be used to alert the user to some
issue.

* [IndexTags](lib/overcommit/hook/post_rewrite/index_tags.rb)
* [SubmoduleStatus](lib/overcommit/hook/post_rewrite/submodule_status.rb)

### PreCommit

`pre-commit` hooks are run after `git commit` is executed, but before the
commit message editor is displayed. If a hook fails, the commit will not be
created. These hooks are ideal for syntax checkers, linters, and other checks
that you want to run before you allow a commit to even be created.

* [`*`AuthorEmail](lib/overcommit/hook/pre_commit/author_email.rb)
* [`*`AuthorName](lib/overcommit/hook/pre_commit/author_name.rb)
* [BerksfileCheck](lib/overcommit/hook/pre_commit/berksfile_check.rb)
* [Brakeman](lib/overcommit/hook/pre_commit/brakeman.rb)
* [`*`BrokenSymlinks](lib/overcommit/hook/pre_commit/broken_symlinks.rb)
* [BundleCheck](lib/overcommit/hook/pre_commit/bundle_check.rb)
* [`*`CaseConflicts](lib/overcommit/hook/pre_commit/case_conflicts.rb)
* [ChamberSecurity](lib/overcommit/hook/pre_commit/chamber_security.rb)
* [CoffeeLint](lib/overcommit/hook/pre_commit/coffee_lint.rb)
* [CssLint](lib/overcommit/hook/pre_commit/css_lint.rb)
* [EsLint](lib/overcommit/hook/pre_commit/es_lint.rb)
* [GoLint](lib/overcommit/hook/pre_commit/go_lint.rb)
* [GoVet](lib/overcommit/hook/pre_commit/go_vet.rb)
* [HamlLint](lib/overcommit/hook/pre_commit/haml_lint.rb)
* [HardTabs](lib/overcommit/hook/pre_commit/hard_tabs.rb)
* [HtmlHint](lib/overcommit/hook/pre_commit/html_hint.rb)
* [HtmlTidy](lib/overcommit/hook/pre_commit/html_tidy.rb)
* [ImageOptim](lib/overcommit/hook/pre_commit/image_optim.rb)
* [JavaCheckstyle](lib/overcommit/hook/pre_commit/java_checkstyle.rb)
* [Jscs](lib/overcommit/hook/pre_commit/jscs.rb)
* [JsHint](lib/overcommit/hook/pre_commit/js_hint.rb)
* [JsLint](lib/overcommit/hook/pre_commit/js_lint.rb)
* [Jsl](lib/overcommit/hook/pre_commit/jsl.rb)
* [JsonSyntax](lib/overcommit/hook/pre_commit/json_syntax.rb)
* [LocalPathsInGemfile](lib/overcommit/hook/pre_commit/local_paths_in_gemfile.rb)
* [`*`MergeConflicts](lib/overcommit/hook/pre_commit/merge_conflicts.rb)
* [Pep257](lib/overcommit/hook/pre_commit/pep257.rb)
* [Pep8](lib/overcommit/hook/pre_commit/pep8.rb)
* [Pyflakes](lib/overcommit/hook/pre_commit/pyflakes.rb)
* [PythonFlake8](lib/overcommit/hook/pre_commit/python_flake8.rb)
* [RailsSchemaUpToDate](lib/overcommit/hook/pre_commit/rails_schema_up_to_date.rb)
* [Reek](lib/overcommit/hook/pre_commit/reek.rb)
* [RuboCop](lib/overcommit/hook/pre_commit/rubo_cop.rb)
* [RubyLint](lib/overcommit/hook/pre_commit/ruby_lint.rb)
* [Scalariform](lib/overcommit/hook/pre_commit/scalariform.rb)
* [Scalastyle](lib/overcommit/hook/pre_commit/scalastyle.rb)
* [ScssLint](lib/overcommit/hook/pre_commit/scss_lint.rb)
* [SemiStandard](lib/overcommit/hook/pre_commit/semi_standard.rb)
* [ShellCheck](lib/overcommit/hook/pre_commit/shell_check.rb)
* [SlimLint](lib/overcommit/hook/pre_commit/slim_lint.rb)
* [Standard](lib/overcommit/hook/pre_commit/standard.rb)
* [TrailingWhitespace](lib/overcommit/hook/pre_commit/trailing_whitespace.rb)
* [TravisLint](lib/overcommit/hook/pre_commit/travis_lint.rb)
* [Vint](lib/overcommit/hook/pre_commit/vint.rb)
* [W3cCss](lib/overcommit/hook/pre_commit/w3c_css.rb)
* [W3cHtml](lib/overcommit/hook/pre_commit/w3c_html.rb)
* [XmlLint](lib/overcommit/hook/pre_commit/xml_lint.rb)
* [XmlSyntax](lib/overcommit/hook/pre_commit/xml_syntax.rb)
* [YamlSyntax](lib/overcommit/hook/pre_commit/yaml_syntax.rb)

### PrePush

`pre-push` hooks are run during `git push`, after remote refs have been updated
but before any objects have been transferred. If a hook fails, the push is
aborted.

* [ProtectedBranches](lib/overcommit/hook/pre_push/protected_branches.rb)
* [RSpec](lib/overcommit/hook/pre_push/r_spec.rb)

### PreRebase

`pre-rebase` hooks are run during `git rebase`, before any commits are rebased.
If a hook fails, the rebase is aborted.

* [MergedCommits](lib/overcommit/hook/pre_rebase/merged_commits.rb)

## Repo-Specific hooks

Out of the box, `overcommit` comes with a set of hooks that enforce a variety of
styles and lints. However, some hooks only make sense in the context of a
specific repository.

At Brigade, for example, we have a number of ad hoc Ruby checks that we run
against our code to catch common errors. For example, since we use
[RSpec](http://rspec.info/), we want to make sure all spec files contain the
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

You can see a great example of writing custom Overcommit hooks from the
following blog post: [How to Write a Custom Overcommit PreCommit
Git Hook in 4 Steps](http://www.guoxiang.me/posts/28-how-to-write-a-custom-overcommit-precommit-git-hook-in-4-steps)

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

Overcommit attempts to address this problem by storing a signature of all
hook plugins since the last time it ran the plugin. When the signature
changes, a warning is displayed alerting you to which plugins have changed.
It is then up to you to manually verify that the changes are not malicious,
and then continue running the hooks.

The signature is derived from the contents of the plugin's source code itself
and any configuration for the plugin. Thus a change to the plugin's source
code or your local repo's `.overcommit.yml` file could result in a signature
change.

### Disabling Signature Checking

In typical usage, your plugins usually don't change too often, so this warning
shouldn't become a nuisance. However, users who work within proprietary
repositories where all developers who can push changes to the repository
already have a minimum security clearance may wish to disable this check.

While not recommended, you can disable signature verification by setting
`verify_plugin_signatures` to `false` in your `.overcommit.yml` file.

## Contributing

We love contributions to Overcommit, be they bug reports, feature ideas, or
pull requests. See our [guidelines for contributing](CONTRIBUTING.md) to best
ensure your thoughts, ideas, or code get merged.

## Community

All major discussion surrounding Overcommit happens on the
[GitHub issues list](https://github.com/brigade/overcommit/issues).

You can also follow [@git_overcommit on Twitter](https://twitter.com/git_overcommit).

## Changelog

If you're interested in seeing the changes and bug fixes between each version
of `overcommit`, read the [Overcommit Changelog](CHANGELOG.md).

## License

This project is released under the [MIT license](MIT-LICENSE).
