require 'singleton'
require 'yaml'

module Overcommit
  class Configuration
    include Singleton

    attr_reader :templates

    def initialize
      @templates = YAML::load_file(File.join(File.dirname(
        File.expand_path(__FILE__)), '..', '..', 'config', 'templates.yml'))
    end
  end

  def self.config
    Configuration.instance
  end
end
