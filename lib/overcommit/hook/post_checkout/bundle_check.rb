module Overcommit::Hook::PostCheckout
  # If Gemfile dependencies were modified since HEAD was changed, check if
  # currently installed gems satisfy the dependencies.
  class BundleCheck < Base
    def run
      unless in_path?('bundle')
        return :warn, 'bundler not installed -- run `gem install bundler`'
      end

      return :warn if dependencies_changed? && !dependencies_satisfied?

      :good
    end

  private

    def dependencies_changed?
      result = command("git diff --exit-code #{new_head} #{previous_head} --name-only")

      result.stdout.split("\n").any? do |file|
        Array(@config['include']).any? { |glob| File.fnmatch(glob, file) }
      end
    end

    def dependencies_satisfied?
      command('bundle check').success?
    end
  end
end
