module Overcommit::Hook::PostCheckout
  # If Gemfile dependencies were modified since HEAD was changed, check if
  # currently installed gems satisfy the dependencies.
  class BundleCheck < Base
    def run
      unless in_path?('bundle')
        return :warn, 'bundler not installed -- run `gem install bundler`'
      end

      if dependencies_changed? && !dependencies_satisfied?
        return :warn, "#{LOCK_FILE} is not up-to-date -- run `bundle check`"
      end

      :pass
    end

  private

    LOCK_FILE = 'Gemfile.lock'

    def dependencies_changed?
      result = execute(%w[git diff --exit-code --name-only] + [new_head, previous_head])

      result.stdout.split("\n").any? do |file|
        Array(@config['include']).any? { |glob| Dir[glob].include?(file) }
      end
    end

    def dependencies_satisfied?
      execute(%w[bundle check]).success?
    end
  end
end
