$LOAD_PATH << File.expand_path('../lib', __FILE__)
require 'overcommit/constants'
require 'overcommit/version'

Gem::Specification.new do |s|
  s.name                  = 'overcommit'
  s.version               = Overcommit::VERSION
  s.license               = 'MIT'
  s.summary               = 'Git hook manager'
  s.description           = 'Utility to install, configure, and extend Git hooks'
  s.authors               = ['Brigade Engineering', 'Shane da Silva']
  s.email                 = ['eng@brigade.com', 'shane.dasilva@brigade.com']
  s.homepage              = Overcommit::REPO_URL
  s.post_install_message  =
    'Install hooks by running `overcommit --install` in your Git repository'

  s.require_paths         = %w[lib]

  s.executables           = ['overcommit']

  s.files                 = Dir['bin/**/*'] +
                            Dir['config/*.yml'] +
                            Dir['lib/**/*.rb'] +
                            Dir['libexec/**/*'] +
                            Dir['template-dir/**/*']

  s.required_ruby_version = '>= 1.9.3'

  s.add_dependency             'childprocess', '~> 0.5.8'
  s.add_dependency             'iniparse', '~> 1.4'

  s.add_development_dependency 'rake', '~> 10.4'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'travis', '~> 1.7'
end
