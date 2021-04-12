# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fusuma/plugin/appmatcher/version'

Gem::Specification.new do |spec|
  spec.name          = 'fusuma-plugin-appmatcher'
  spec.version       = Fusuma::Plugin::Appmatcher::VERSION
  spec.authors       = ['iberianpig']
  spec.email         = ['yhkyky@gmail.com']

  spec.summary       = 'Fusuma plugin to assign gesture mapping per application'
  spec.description   = 'fusuma-plugin-appmatcher is Fusuma plugin for assigning gesture mapping per application.'
  spec.homepage      = 'https://github.com/iberianpig/fusuma-plugin-appmatcher'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'iniparse'
  spec.add_runtime_dependency 'ruby-dbus'

  spec.add_dependency 'fusuma', '~> 2.0.0'
end
