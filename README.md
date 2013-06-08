[![Gem Version](https://badge.fury.io/rb/overcommit.png)](https://badge.fury.io/rb/overcommit)
[![Build Status](https://travis-ci.org/causes/overcommit.png)](https://travis-ci.org/causes/overcommit)

# Overcommit

A gem to install and manage a configurable (but opinionated) set of Git hooks.
Originally written for use at [Causes](https://github.com/causes).

In addition to supporting global hooks, it also allows teams to define plugins
specific to a repository (installed in the `.githooks` directory).

[Read more](http://causes.github.io/blog/2013/05/30/overcommit-the-opinionated-git-hook-manager/)
about overcommit on our [engineering blog](http://causes.github.io).

## Installation

The `overcommit` is installed as a binary via rubygems:

    gem install overcommit

You can then run the `overcommit` command to install hooks into repositories:

    mkdir important-project
    cd important-project
    git init
    overcommit .

`overcommit` also accepts a handful of arguments, which can be enumerated by
running `overcommit --help`.

At [Causes](https://github.com/causes), we install all of the hooks via the
`--all` flag. In absence of this flag, you will be given the `default` template.
For more information, try `overcommit --list-templates`.

## Dependencies

Some of the lints have third-party dependencies. For example, to lint your
[SCSS](http://sass-lang.com/) files, you're going to need our [scss-lint
gem](https://github.com/causes/scss-lint):

    gem install scss-lint

Other useful utilities include `jshint`, which can be installed via `npm`:

    npm install -g jshint

## Built-in hooks

There are two types of hooks installed by this utility. `post-checkout`,
`post-merge`, and `prepare-commit-msg` are all simple shell scripts rolled by
hand for use at Causes. We think other people may find them useful.

The second, more interesting type is the Ruby-based, extensible checks. These
are currently `pre-commit` and `commit-msg`. These are used for checking the
validity of the code to be committed and checking the content of the commit
message, respectively.

You can see the various sub-hooks available in the `lib/overcommit/plugins`
directory:

    >> tree lib/overcommit/plugins
    lib/overcommit/plugins
    ├── commit_msg
    │   ├── change_id.rb
    │   ├── release_note.rb
    │   ├── russian_novel.rb
    │   ├── text_width.rb
    │   └── trailing_period.rb
    └── pre_commit
        ├── author_name.rb
        ├── causes_email.rb
        ├── coffee_lint.rb
        ├── css_linter.rb
        ├── erb_syntax.rb
        ├── haml_syntax.rb
        ├── js_console_log.rb
        ├── js_syntax.rb
        ├── python_flake8.rb
        ├── restricted_paths.rb
        ├── ruby_syntax.rb
        ├── scss_lint.rb
        ├── test_history.rb
        ├── whitespace.rb
        └── yaml_syntax.rb

Most of them are straightforward lints, with an easter egg or two thrown in for
good measure. Because some of these are Causes-specific (for instance, we
insert a 'Change-Id' at the end of each commit message for Gerrit code review),
the default installation will skip loading some of these checks.

## Repo-specific hooks

Out of the box, `overcommit` comes with a set of hooks that enforce a variety of
styles and lints. However, some hooks only make sense in the context of a given
repository.

At Causes, for example, we have a repository for managing our
[Chef](http://www.opscode.com/chef/) cookbooks. Inside this repository, we have
a few additional lints we run before commits are pushed:

    >> tree .githooks
    .githooks
    └── pre_commit
        ├── berksfile_source.rb
        ├── cookbook_version.rb
        └── food_critic.rb

`food_critic.rb` contains a subclass of `HookSpecificCheck` that runs
[Foodcritic](http://acrmp.github.io/foodcritic/) against the cookbooks about to
be committed (if any).

The meat of it looks like this:

```ruby
module Overcommit::GitHook
  class FoodCritic < HookSpecificCheck
    include HookRegistry
    COOKBOOKS = 'cookbooks'
    @@options = { :tags => %w[~readme ~fc001] }

    def run_check
      begin
        require 'foodcritic'
      rescue LoadError
        return :stop, 'run `bundle install` to install the foodcritic gem'
      end

      changed_cookbooks = modified_files.map do |file|
        file.split('/')[0..1].join('/') if file.start_with? COOKBOOKS
      end.compact.uniq

      linter = ::FoodCritic::Linter.new
      review = linter.check(changed_cookbooks, @@options)
      return (review.warnings.any? ? :bad : :good), review
    end
  end
end
```

## Other functionality

In addition to the Ruby-based plugin system, `overcommit` also ships with a few
handy shell scripts:

- `post-checkout` runs `ctags` after checkouts to aid in tag-based navigation.
  We use this in combination with Vim by adding `.git/tags` to the `tags`
  configuration:

        set tags=.git/tags,.tags

- `post-merge` checks for updated submodules and prompts you to update them.

- `prepare-commit-msg` sets up your commit message to include additional author
  information and note submodule changes when updating.

## Uninstallation

If you'd like to remove the hooks from a repository, just pass the `--uninstall`
flag:

    overcommit --uninstall important-project

## Contributing

Pull requests and issues are welcome. New features should ship with tests so
that we can avoid breaking them in the future.

## License

Released under the MIT License.
