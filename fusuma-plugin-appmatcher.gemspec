# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "fusuma/plugin/appmatcher/version"

Gem::Specification.new do |spec|
  spec.name          = "fusuma-plugin-appmatcher"
  spec.version       = Fusuma::Plugin::Appmatcher::VERSION
  spec.authors       = ["iberianpig"]
  spec.email         = ["yhkyky@gmail.com"]

  spec.summary       = "Fusuma plugin to assign gesture mapping per application"
  spec.description   = "fusuma-plugin-appmatcher is Fusuma plugin for assigning gesture mapping per application."
  spec.homepage      = "https://github.com/iberianpig/fusuma-plugin-appmatcher"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  spec.files          = Dir["{bin,lib,exe}/**/*", "LICENSE*", "README*", "*.gemspec"]
  spec.test_files     = Dir["{test,spec,features}/**/*"]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rexml" # ruby-dbus doesn't resolve dependency
  spec.add_runtime_dependency "ruby-dbus"

  spec.add_dependency "fusuma", "~> 2.3"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.required_ruby_version = ">= 2.5.1" # https://packages.ubuntu.com/search?keywords=ruby&searchon=names&exact=1&suite=all&section=main
  # support bionic (18.04LTS) 2.5.1
end
