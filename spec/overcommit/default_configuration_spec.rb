require 'spec_helper'

describe 'default configuration' do
  default_config =
    YAML.load_file(Overcommit::ConfigurationLoader::DEFAULT_CONFIG_PATH).to_hash

  Overcommit::Utils.supported_hook_types.each do |hook_type|
    hook_class = Overcommit::Utils.camel_case(hook_type)

    Dir[File.join(Overcommit::HOOK_DIRECTORY, hook_type.tr('-', '_'), '*')].
      map { |hook_file| Overcommit::Utils.camel_case(File.basename(hook_file, '.rb')) }.
      each do |hook|
      next if hook == 'Base'

      context "for the #{hook} #{hook_type} hook" do
        it 'exists in config/default.yml' do
          default_config[hook_class][hook].should_not be_nil
        end

        it 'explicitly sets the enabled option' do
          # Use variable names so it reads nicer in the RSpec output
          hook_enabled_option_set = !default_config[hook_class][hook]['enabled'].nil?
          all_hook_enabled_option_set = !default_config[hook_class]['ALL']['enabled'].nil?

          (hook_enabled_option_set || all_hook_enabled_option_set).should == true
        end

        it 'defines a description' do
          default_config[hook_class][hook]['description'].should_not be_nil
        end
      end
    end
  end
end
