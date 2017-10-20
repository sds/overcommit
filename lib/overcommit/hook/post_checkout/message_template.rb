module Overcommit::Hook::PostCheckout
  class MessageTemplate < Base
    def run
      Overcommit::Utils.log.debug("Checking if '#{Overcommit::GitRepo.current_branch}' matches #{branch_pattern}")
      if branch_pattern.match?(Overcommit::GitRepo.current_branch)
        set_commit_template
        :pass
      else
        :warn
      end
    end

    def set_commit_template
      Overcommit::Utils.log.debug("Writing #{git_template_filename} with #{new_template}")
      File.write(git_template_filename, new_template)
      `git config commit.template #{git_template_filename}`
    end

    def new_template
      new_template ||= Overcommit::GitRepo.current_branch.gsub(branch_pattern, replacement_text)
    end

    def branch_pattern
      @branch_pattern ||=
        begin
          pattern = config['branch_pattern']
          Regexp.new(pattern.empty? ? '\A.*\w+[-_](\d+).*\z' : pattern)
        end
    end

    def replacement_text
      @replacement_text ||=
        begin
          if File.exists?(replacement_text_config)
            File.read(replacement_text_config)
          else
            replacement_text_config
          end
        end
    end

    def replacement_text_config
      @replacement_text_config ||= config['replacement_text']
    end

    def git_template_filename
      config['git_template_filename'] || 'overcommit_message_template.txt'
    end
  end
end
