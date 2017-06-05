module Overcommit::Hook::PrePush
  # Runs `rspec` test suite before push
  # .overcommit.yml configuration:
  # Set `changed: true` to run rspec only over edited files.
  # Set `remote`: $remote_name` to specify a remote name.
  #
  # @see http://rspec.info/
  class RSpec < Base
    def run
      command = ['rspec']
      remote = config['remote'] || 'origin'
      result = if config['changed']
                 return :pass if testable_files(remote).empty?
                 execute([*command, *testable_files(remote)])
               else
                 execute(command)
               end
      return :pass if result.success?

      output = result.stdout + result.stderr
      [:fail, output]
    end

    def testable_files(remote)
      return [] if Overcommit::GitRepo.modified_file_in_branch(remote).empty?
      files = Overcommit::GitRepo.modified_file_in_branch(remote).map do |file_path|
        if test?(file_path) || ruby_file?(file_path)
          test?(file_path) ? file_path : spec_file(file_path)
        end
      end
      files.uniq.reject { |file| file.nil? || file == false }
    end

    def test?(file_path)
      file_path.start_with?('spec/') && file_path.end_with?('_spec.rb')
    end

    def ruby_file?(file_path)
      file_path.end_with? '.rb'
    end

    def spec_file(file_path)
      spec_path = "spec/#{file_path.insert(-4, '_spec')}".delete('/app')
      Pathname.new(spec_path).exist? ? spec_path : false
    end
  end
end
