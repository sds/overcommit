require 'spec_helper'

describe 'default configuration' do
  default_config =
    YAML.load_file(Overcommit::ConfigurationLoader::DEFAULT_CONFIG_PATH).to_hash

  Overcommit::Utils.supported_hook_type_classes.each do |hook_type|
    context "within the #{hook_type} configuration section" do
      default_config[hook_type].each do |hook_name, hook_config|
        next if hook_name == 'ALL'

        it "explicitly sets the `enabled` option for #{hook_name}" do
          # Use variable names so it reads nicer in the RSpec output
          hook_enabled_option_set = !hook_config['enabled'].nil?
          all_hook_enabled_option_set = !default_config[hook_type]['ALL']['enabled'].nil?

          (hook_enabled_option_set || all_hook_enabled_option_set).should == true
        end
      end
    end
  end
end
