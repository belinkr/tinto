# encoding: utf-8
require 'json'
require 'sanitize'

module Tinto
  class Sanitizer
    def self.sanitize(input, config = Sanitize::Config::RELAXED)
      Sanitize.clean(input, config).to_s
    end

    def self.sanitize_array(array = [])
      array.collect do |item|
        case item
          when Hash
            sanitize_hash(item)
          when String
            sanitize(item)
          when Array
            sanitize_array(item)
          else
            item
        end # case
      end # collect
    end

    # For sanitize params & payload hashes
    def self.sanitize_hash(hash={})
      return {} unless hash.is_a?(Hash)
      return {} if hash.empty?
      hash = hash.dup
      hash.each do |key, value|
        case value
          when Hash
            hash[key] = sanitize_hash(value)
          when String
            hash[key] = sanitize(value)
          when Array
            hash[key] = sanitize_array(value)
          else
        end
      end
      hash
    end

    # For presenter
    def self.sanitize_hash2json(hash={})
      sanitize_hash(hash).to_json
    end
  end # Sanitizer
end # Tinto
