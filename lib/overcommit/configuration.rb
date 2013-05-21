require 'singleton'
require 'yaml'

module Overcommit
  class Configuration
    include Singleton

    attr_reader :templates

    def initialize
      @templates = YAML::load_file(Utils.absolute_path('config/templates.yml'))
    end
  end

  def self.config
    Configuration.instance
  end
end
