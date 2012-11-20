# encoding: utf-8
module Tinto
  class SortedSet
    class RedisBackend
      include Enumerable

      def initialize(storage_key)
        @storage_key = storage_key
      end #initialize

      def fetch(from=0, to=-1)
        range = $redis.zrevrange(@storage_key, from, to, with_scores: true)
          .map { |element, score| [score, element ] }
      end #fetch

      def each
        return Enumerator.new(self, :each) unless block_given?
        fetch.each { |score, element| yield element }
      end #each

      def size
        $redis.zcard @storage_key
      end #size

      def score(element)
        $redis.zscore @storage_key, element.to_s
      end

      def include?(element)
        !!($redis.zscore @storage_key, element.to_s)
      end #include?

      def first
        fetch.first
      end #first

      def add(score, element)
        $redis.zadd @storage_key, score, element
      end #add

      def merge(scores_and_elements=[])
        unless scores_and_elements.empty?
          $redis.zadd @storage_key, scores_and_elements
        end
      end #merge

      def delete(element)
        $redis.zrem @storage_key, element
      end #delete

      def clear
        $redis.del @storage_key
      end #clear
    end # RedisBackend
  end # SortedSet
end # Tinto

