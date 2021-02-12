# frozen_string_literal: true

require_relative './lib/overcommit/constants'
require_relative './lib/overcommit/version'

Gem::Specification.new do |s|
  s.name                  = 'overcommit'
  s.version               = Overcommit::VERSION
  s.license               = 'MIT'
  s.summary               = 'Git hook manager'
  s.description           = 'Utility to install, configure, and extend Git hooks'
  s.authors               = ['Shane da Silva']
  s.email                 = ['shane@dasilva.io']
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

  s.required_ruby_version = '>= 2.4'

  s.add_dependency          'childprocess', '>= 0.6.3', '< 5'
  s.add_dependency          'iniparse', '~> 1.4'
  s.add_dependency          'rexml', '~> 3.2'
end
