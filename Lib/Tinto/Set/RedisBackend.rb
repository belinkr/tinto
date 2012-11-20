# encoding: utf-8
require 'set'

module Tinto
  class Set
    class RedisBackend
      include Enumerable

      attr_reader :storage_key

      def initialize(storage_key)
        @storage_key = storage_key
      end #initialize

      def fetch
        $redis.smembers @storage_key
      end #fetch

      def each
        return Enumerator.new(self, :each) unless block_given?
        fetch.each { |id| yield id }
      end #each

      def size
        $redis.scard @storage_key
      end #size

      def include?(element)
        $redis.sismember @storage_key, element.to_s
      end #include?

      def first
        fetch.first
      end #first

      def add(element)
        $redis.sadd @storage_key, element 
      end #add

      def merge(elements=[])
        $redis.sadd @storage_key, elements unless elements.empty?
      end #merge

      def delete(element)
        $redis.srem @storage_key, element
      end #delete

      def clear
        $redis.del @storage_key
      end #clear

      def |(set_or_enumerable)
        if set_or_enumerable.respond_to? :storage_key
          ::Set.new($redis.sunion @storage_key, set_or_enumerable.storage_key)
        else
          ::Set.new(fetch + set_or_enumerable)
        end
      end

      alias_method :union, :|

    end # RedisBackend
  end # Set
end # Tinto

