require 'overcommit'

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each { |f| require f }

Dir[File.dirname(__FILE__) + '/../lib/overcommit/plugins/**/*.rb'].each do |f|
  require f
end

RSpec.configure do |config|
  config.color_enabled = true
  config.tty = true
  config.formatter = :documentation

  # For commit message check tests, just specify the commit_msg for each context
  config.before :each,
                example_group: { file_path: %r{\bspec/plugins/commit_msg/} } do
    subject.stub(:commit_message).and_return(commit_msg.split("\n"))
  end
end

def exit(*args) ; end

Overcommit::Logger.instance.output = StringIO.new
