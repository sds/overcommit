$: << File.expand_path('../lib', __FILE__)
require 'overcommit/version'

Gem::Specification.new do |s|
  s.name              = 'overcommit'
  s.version           = Overcommit::VERSION
  s.license           = 'MIT'

  s.summary     = 'Opinionated git hook manager'
  s.description = 'Overcommit is a utility to install and extend git hooks'

  s.authors  = ['Causes Engineering']
  s.email    = 'eng@causes.com'
  s.homepage = 'http://github.com/causes/overcommit'

  s.require_paths = %w[lib]

  s.executables = ['overcommit']

  s.files = `git ls-files -- lib`.split("\n")
end
