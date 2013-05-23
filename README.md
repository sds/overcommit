# Overcommit

A gem to install and manage a configurable (but opinionated) set of Git hooks.
Originally written for use at [Causes](https://www.github.com/causes).

In addition to supporting global hooks, it also allows teams to define plugins
specific to a repository (installed in the `.githooks` directory).

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
    include HookRegistroy
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
