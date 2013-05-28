# Overcommit

A gem to install and manage a configurable (but opinionated) set of Git hooks.
Originally written for use at [Causes](https://github.com/causes).

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

At [Causes](https://github.com/causes), we install all of the hooks via the
`--all` flag. In absence of this flag, you will be given the `default` template.
For more information, try `overcommit --list-templates`.

## Built-in hooks

There are two types of hooks installed by this utility. `post-checkout`,
`post-merge`, and `prepare-commit-msg` are all simple shell scripts rolled by
hand for use at Causes. We think other people may find them useful.

The second, more interesting type is the Ruby-based, extensible checks. These
are currently `pre-commit` and `commit-msg`. These are used for checking the
validity of the code to be comitted and checking the content of the commit
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
        ├── css_linter.rb
        ├── erb_syntax.rb
        ├── haml_syntax.rb
        ├── js_console_log.rb
        ├── js_syntax.rb
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

## Contributing

Pull requests and issues are welcome. Although spec coverage is minimal at the
moment, new features should ship with tests so that we can avoid breaking them
in the future.

## License

Released under the MIT License.
