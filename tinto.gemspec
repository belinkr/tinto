# encoding: utf-8
$:.unshift File.expand_path('../Lib', __FILE__)
require 'Tinto/Version'
require 'Tinto/GemConfig'

gem_config = Tinto::GemConfig.new
Gem::Specification.new do |s|
  s.name          = gem_config.name
  s.version       = gem_config.version
  s.platform      = Gem::Platform::RUBY
  s.authors       = gem_config.authors
  s.email         = gem_config.email
  s.homepage      = gem_config.homepage
  s.summary       = gem_config.summary
  s.description   = gem_config.description
  s.require_paths = gem_config.require_paths
  s.files         = Dir.glob('./Lib/Tinto/**/*.rb') + 
                    Dir.glob('./Lib/Tinto/**/*.class')

  gem_config.runtime_dependencies.each do |dependency|
    s.add_runtime_dependency dependency
  end

  gem_config.development_dependencies.each do |dependency|
    s.add_development_dependency dependency
  end
end

