require 'overcommit'

hook_types = Dir[File.join(Overcommit::OVERCOMMIT_HOME, 'lib/overcommit/hook/*')].
  select { |f| File.directory?(f) }.
  sort

hook_types.each do |hook_type|
  require File.join(hook_type, 'base.rb')
  Dir[File.join(hook_type, '**/*.rb')].
    select { |f| File.file?(f) && File.basename(f, '.rb') != 'base' }.
    sort.
    each { |f| require f }
end

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each { |f| require f }

RSpec.configure do |config|
  #config.color_enabled = true
  #config.tty = true
  #config.formatter = :documentation

  config.include GitSpecHelpers

  # For commit message check tests, just specify the commit_msg for each context
  #config.before :each,
                #:example_group => { :file_path => %r{\bspec/plugins/commit_msg/} } do
    #subject.stub(:raw_commit_message).and_return(commit_msg.split("\n"))
  #end
end
