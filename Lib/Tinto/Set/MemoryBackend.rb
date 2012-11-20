# encoding: utf-8
require 'forwardable'
require 'set'

module Tinto
  class Set
    class MemoryBackend
      include Enumerable
      extend Forwardable

      FORWARDED_METHODS = %w{ each size empty? clear first }
      def_delegators :@elements, *FORWARDED_METHODS

      def initialize
        @elements = ::Set.new
      end #initialize

      def include?(element)
        @elements.include? element.to_s
      end #include?

      def add(element)
        @elements.add(element.to_s)
      end #add

      def merge(elements)
        @elements.merge(elements.map { |element| element.to_s }.to_a)
      end #merge

      def delete(element)
        @elements.delete(element.to_s)
      end #delete

      def |(enumerable)
        ::Set.new.merge(@elements + enumerable)
      end

      alias_method :union, :|

    end # MemoryBackend
  end # Set
end # Tinto

