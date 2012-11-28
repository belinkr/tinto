# encoding: utf-8
$:.unshift File.expand_path('../Lib', __FILE__)
require 'warbler'
require 'Tinto/Version'
require 'Tinto/GemConfig'

task :jar => [:compile, :clean_up]
task :compiled_gem => [:package_gem, :clean_up]

task :compile do
  jar             = Warbler::Jar.new
  config          = Warbler::Config.new
  config.dirs     = ['./Lib/Tinto']
  config.includes = ['./tinto.gemspec']

  compiler        = Tinto::Compiler.new(jar, config)
  compiler.compile
end

task :clean_up do
  Tinto::Compiler.new.clean_up
end

task :package_gem do
  jar             = Warbler::Jar.new
  config          = Warbler::Config.new
  config.dirs     = ['./Lib/Tinto']
  config.includes = ['./tinto.gemspec']

  compiler        = Tinto::Compiler.new(jar, config)
  compiler.compile

  gem_config  = Tinto::GemConfig.new
  spec        = Gem::Specification.new do |s|
    s.name          = gem_config.name
    s.version       = gem_config.version
    s.platform      = Gem::Platform::RUBY
    s.authors       = gem_config.authors
    s.email         = gem_config.email
    s.homepage      = gem_config.homepage
    s.summary       = gem_config.summary
    s.description   = gem_config.description
    s.require_paths = gem_config.require_paths
    s.files         = jar.files.values.select {|f|f.class == String }

    gem_config.runtime_dependencies.each do |dependency|
      s.add_runtime_dependency dependency
    end

    gem_config.development_dependencies.each do |dependency|
      s.add_development_dependency dependency
    end
  end

  Gem::Builder.new(spec).build
end

module Tinto
  class Compiler
    def initialize(jar=nil, config=nil)
      @jar        = jar    || Warbler::Jar.new
      @config     = config || Warbler::Config.new
      @jar_name   = 'tinto.jar'
      @base_path  = './Lib'
    end #initialize

    def compile
      jar.find_application_files(config)
      jar.compile(config)
      puts jar.files
      puts jar.app_filelist
      jar.create(jar_name)
    end #compile

    def clean_up
      puts 'Removing generated java classes'
      Dir.glob(["#{base_path}/**/*.class"]).each { |file| 
        File.delete(file)
        puts "-- Removing #{File.expand_path file}"
      }
    end #remove_files

    private 

    attr_reader :jar, :config, :jar_name, :base_path
  end # Compiler
end # Tinto

