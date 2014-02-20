$LOAD_PATH << File.expand_path('../lib', __FILE__)
require 'overcommit/constants'
require 'overcommit/version'

Gem::Specification.new do |s|
  s.name                  = 'overcommit'
  s.version               = Overcommit::VERSION
  s.license               = 'MIT'
  s.summary               = 'Git hook manager'
  s.description           = 'Utility to install, configure, and extend Git hooks'
  s.authors               = ['Causes Engineering', 'Shane da Silva']
  s.email                 = ['eng@causes.com', 'shane@causes.com']
  s.homepage              = Overcommit::REPO_URL
  s.post_install_message  =
    'Install hooks by running `overcommit --install` in your Git repository'

  s.require_paths         = %w[lib]

  s.executables           = ['overcommit']

  s.files                 = Dir['bin/**/*'] +
                            Dir['config/*.yml'] +
                            Dir['lib/**/*.rb']

  s.required_ruby_version = '>= 1.8.7'

  s.add_dependency             'wopen3'

  s.add_development_dependency 'rspec', '2.14.1'
  s.add_development_dependency 'image_optim', '0.10.2'
end
