# encoding: utf-8
require 'ostruct'
require 'Tinto/Version'

module Tinto
  class GemConfig
    def initialize
      @config = OpenStruct.new(
        name:           'tinto',
        version:        Tinto::VERSION,
        platform:       Gem::Platform::RUBY,
        authors:        ['Lorenzo Planas'],
        email:          ['lorenzo@qindio.com'],
        homepage:       'http://qindio.com',
        summary:        'A sample gem',
        description:    'Blah blah blah',
        require_paths:  ['Lib'],
        runtime_dependencies: [
          'i18n',
          'json',
          'sanitize',
          'uuidtools',
          'aequitas',
          'redis'
        ],
        development_dependencies: [
          'warbler',
          'minitest',
          'guard',
          'guard-minitest'
        ]
      )
    end #initialize

    def method_missing(method, *args)
      @config.send method, *args || raise
    end #method_missing

    private

    attr_reader :config
  end # GemConfig
end # Tinto

