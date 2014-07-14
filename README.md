[![Gem Version](https://badge.fury.io/rb/overcommit.svg)](https://badge.fury.io/rb/overcommit)
[![Build Status](https://travis-ci.org/causes/overcommit.svg)](https://travis-ci.org/causes/overcommit)
[![Code Climate](https://codeclimate.com/github/causes/overcommit.png)](https://codeclimate.com/github/causes/overcommit)
[![Dependency Status](https://gemnasium.com/causes/overcommit.svg)](https://gemnasium.com/causes/overcommit)

# Overcommit

`overcommit` is a tool to manage and configure
[Git hooks](http://git-scm.com/book/en/Customizing-Git-Git-Hooks).

In addition to supporting a wide variety of hooks that can be used across
multiple repositories, you can also define hooks specific to a
repository (but unlike regular Git hooks, are stored with that repository).

[Read more](http://causes.github.io/blog/2013/05/30/overcommit-the-opinionated-git-hook-manager/)
about Overcommit on our [engineering blog](http://causes.github.io).

* [Requirements](#requirements)
  * [Dependencies](#dependencies)
* [Installation](#installation)
  * [Automatically Install Overcommit Hooks](#automatically-install-overcommit-hooks)
* [Usage](#usage)
* [Configuration](#configuration)
* [Built-In Hooks](#built-in-hooks)
* [Repo-Specific Hooks](#repo-specific-hooks)
* [Security](#security)
* [Contributing](#contributing)
* [Changelog](#changelog)
* [License](#license)

## Requirements

The following Ruby versions are supported:

* 1.8.7
* 1.9.3
* 2.0.0
* 2.1.x
* JRuby 1.7.9 in Ruby 1.9 mode

### Dependencies

Some of the hooks have third-party dependencies. For example, to lint your
[SCSS](http://sass-lang.com/) files, you're going to need our
[scss-lint gem](https://github.com/causes/scss-lint).

Depending on the hooks you enable/disable for your repository, you'll need to
ensure your development environment already has those dependencies installed.
Most hooks will display a warning if a required executable isn't available.

## Installation

`overcommit` is installed as a binary via [RubyGems](https://rubygems.org/):

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
`-t`/`--template-dir`     | Print location of template directory
`-h`/`--help`             | Show command-line flag documentation
`-v`/`--version`          | Show version

### Skipping Hooks

Sometimes a hook will report an error that for one reason or another you'll want
to ignore. To prevent these errors from blocking your commit, you can include
the name of the relevant hook in the `SKIP` environment variable, e.g.

```bash
SKIP=rubocop git commit
```

Use this feature sparingly, as there is no point to having the hook in the first
place if you're just going to ignore it. If you want to ensure a hook is never
skipped, set the `required` option to `true` in its configuration.

## Configuration

Overcommit provides a flexible configuration system that allows you to tailor
the built-in hooks to suit your workflow. All configuration specific to a
repository is stored in `.overcommit.yml` in the top-level directory of the
repository.

When writing your own configuration, it will automatically extend the
[default configuration](config/default.yml), so you only need to specify
your configuration with respect to the default. In order to
enable/disable the default hooks, you can add the following to your repo-specific
configuration file:

```yaml
PreCommit:
  Rubocop:
    enabled: false
```

Within a configuration file, the following high-level concepts exist:

* **Plugin Directory**: allows you to specify the directory where your own
  Git hook plugins are stored (if you have project-specific hooks)

* **Hook type configuration (`PreCommit`, `CommitMsg`, etc.)**: these
  categories each contain a list of hooks that are available for the respective
  hook type. One special hook is the `ALL` hook, which allows you to define
  configuration that applies to all hooks of the given type.

* **Hook configuration**: Within each hook category, an individual hook can
  be configured with the following properties:

  * `enabled`: if false, this hook will not be enabled
  * `required`: if true, this hook cannot be skipped via the `SKIP` environment
    variable
  * `quiet`: if true, this hook does not display anything unless it fails
  * `description`: text displayed when the hook is running
  * `requires_files`: whether this hook should run only if files have been
    modified
  * `include`: Glob patterns of files that apply to this hook (it will run
    only if a file matching the pattern has been modified--note that the
    concept of "modified" varies for different types of hooks)
  * `exclude`: Glob patterns of files that are ignored by this hook

  On top of the above built-in configuration options, each hook can support
  individual configuration. As an example, the `AuthorEmail` hook allows you
  to customize the regex used to check emails via the `pattern` option, which
  is useful if you want to enforce developers to use a company email address
  for their commits.

## Built-In Hooks

Currently, Overcommit supports `commit-msg`, `pre-commit`, and `post-checkout`
hooks, but it can easily be expanded to support others.

You can see the full list of hooks by checking out the
[hooks directory](https://github.com/causes/overcommit/blob/master/lib/overcommit/hook),
and view their [default configuration](config/default.yml).

## Repo-Specific hooks

Out of the box, `overcommit` comes with a set of hooks that enforce a variety of
styles and lints. However, some hooks only make sense in the context of a given
repository.

At Causes, for example, we have a number of ad hoc Ruby checks that we run
against our code to catch common errors. For example, since we use
[RSpec](http://rspec.info/), we want to make sure all spec files contain the
line `require 'spec_helper'`.

Inside our repository, we can add the following file to `.git-hooks/pre_commit`
in order to automatically check our spec files:

```ruby
module Overcommit::Hook::PreCommit
  class EnsureSpecHelper < Base
    errors = []

    applicable_files.each do |file|
      if File.open(file, 'r').read !~ /^require 'spec_helper'/
        errors << "#{file}: missing `require 'spec_helper'`"
      end
    end

    return :bad, errors.join("\n") if errors.any?

    :good
  end
end
```

The corresponding configuration for this hook would look like:

```yaml
PreCommit:
  EnsureSpecHelper:
    description: 'Checking for missing inclusion of spec_helper'
    include: '**/*_spec.rb'
```

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

We love getting feedback with or without pull requests. If you do add a new
feature, please add tests so that we can avoid breaking it in the future.

Speaking of tests, we use `rspec`, which can be run like so:

```bash
bundle exec rspec
```

## Changelog

If you're interested in seeing the changes and bug fixes between each version
of `overcommit`, read the [Overcommit Changelog](CHANGELOG.md).

## License

This project is released under the [MIT license](MIT-LICENSE).
