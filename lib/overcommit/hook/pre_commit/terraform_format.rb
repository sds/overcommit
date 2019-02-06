# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Runs 'terraform fmt' against any modified *.tf files.
  #
  # @see https://www.terraform.io/docs/commands/fmt.html
  class TerraformFormat < Base
    def run
      messages = []
      applicable_files.each do |f|
        result = execute(command, args: [f])
        unless result.success?
          messages << Overcommit::Hook::Message.new(:error, f, nil, "violation found in #{f}")
        end
      end
      messages
    end
  end
end
