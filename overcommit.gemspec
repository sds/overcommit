$: << File.expand_path('../lib', __FILE__)
require 'overcommit/version'

Gem::Specification.new do |s|
  s.name              = 'overcommit'
  s.version           = Overcommit::VERSION
  s.license           = 'MIT'

  s.summary     = 'Opinionated Git hook manager'
  s.description = 'Overcommit is a utility to install and extend Git hooks'

  s.authors  = ['Causes Engineering']
  s.email    = 'eng@causes.com'
  s.homepage = 'http://github.com/causes/overcommit'

  s.require_paths = %w[lib]

  s.executables = ['overcommit']

  s.files = Dir['lib/**/*.rb'] +
            Dir['bin/**/*'] +
            Dir['config/*.yml']

  s.add_development_dependency 'rspec', '2.14.1'
  s.add_development_dependency 'image_optim', '0.9.1'
end
