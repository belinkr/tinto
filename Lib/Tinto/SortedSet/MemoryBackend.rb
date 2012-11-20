# encoding: utf-8
require 'forwardable'
require 'set'

module Tinto
  class SortedSet
    class MemoryBackend
      include Enumerable
      extend Forwardable

      FORWARDED_METHODS = %w{ size empty? first }
      def_delegators :@elements, *FORWARDED_METHODS

      def initialize
        @elements = ::Set.new
        @scores     = {}
      end #initialize

      def each
        @elements.each { |element| yield [@scores.fetch(element), element] }
      end #each

      def score(element)
        @scores.fetch(element.to_s, nil)
      end

      def include?(element)
        @elements.include? element.to_s
      end #include?

      def add(score, element)
        element = element.to_s
        @elements.add(element)
        @scores[element] = score
      end #add

      def merge(scores_and_elements)
        scores_and_elements.each { |score, element| add score, element }
      end #merge

      def delete(element)
        element = element.to_s
        @elements.delete(element)
        @scores.delete element
      end #delete

      def clear
        @scores.clear
        @elements.clear
      end #clear
    end # MemoryBackend
  end # SortedSet
end # Tinto

