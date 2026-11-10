# frozen_string_literal: true

require 'stringio'

# Prepare installed hooks without booting a separate fixture CLI process.
# CLI and Gemfile-loading integration tests still invoke the real executable.
module ShellHelpers
  def install_overcommit_hooks
    %w[repo_root git_dir].each { |name| Overcommit::Utils.instance_variable_set("@#{name}", nil) }
    logger = Overcommit::Logger.new(StringIO.new)
    Overcommit::Installer.new(logger).run(Dir.pwd, action: :install)
  ensure
    %w[repo_root git_dir].each { |name| Overcommit::Utils.instance_variable_set("@#{name}", nil) }
  end
end
