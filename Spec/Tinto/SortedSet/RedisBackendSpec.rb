# encoding: utf-8
$:.unshift File.expand_path('../../../../Lib', __FILE__)
require 'minitest/autorun'
require 'ostruct'
require 'redis'
require_relative '../../../Lib/Tinto/SortedSet/RedisBackend'

describe Tinto::SortedSet::RedisBackend do 
  $redis ||= Redis.new
  $redis.select 8

  before do
    $redis.flushdb
    @storage_key = 'test'
  end
  
  describe '#initialize' do
    it 'requires a storage_key' do
      lambda { Tinto::SortedSet::RedisBackend.new }.must_raise ArgumentError
      Tinto::SortedSet::RedisBackend.new @storage_key
    end
  end #initialize

  describe '#fetch' do
    it 'gets all elements stored in the DB' do
      zset = Tinto::SortedSet::RedisBackend.new(@storage_key)
      zset.add score_for(1), 1
      zset.fetch.size.must_equal 1
    end
  end #fetch

  describe '#each' do
    it 'returns an enumerator if no block given' do
      zset = Tinto::SortedSet::RedisBackend.new(@storage_key)
      zset.each.must_be_instance_of Enumerator
    end

    it 'yields the elements as strings' do
      zset = Tinto::SortedSet::RedisBackend.new(@storage_key)
      zset.add score_for(1), 1
      zset.each { |element, score| element.must_be_instance_of String }
    end
  end #each

  describe '#size' do
    it 'returns the number of elements in the zset' do
      zset = Tinto::SortedSet::RedisBackend.new(@storage_key)
      zset.add score_for(1), 1
      zset.size.must_equal 1
    end
  end #size

  describe '#include?' do
    it 'returns true if the zset includes the passed id' do
      zset = Tinto::SortedSet::RedisBackend.new(@storage_key)
      zset.add score_for(1), 1
      zset.include?('1').must_equal true
      zset.include?(1).must_equal true
    end
  end #include?

  describe '#first' do
    it 'returns the first element in the zset according to scores' do
      zset = Tinto::SortedSet::RedisBackend.new(@storage_key)
      zset.add score_for(1), 1
      zset.add score_for(2), 2
      zset.first.must_include '2'
    end
  end #first

  describe '#add' do
    it 'adds the id of a member to the zset, if not included yet' do
      zset = Tinto::SortedSet::RedisBackend.new(@storage_key)
      zset.add score_for(1), 1
      4.times { zset.add score_for(2), 2 }
      zset.size.must_equal 2

      zset.add score_for(3), 3
      zset.size.must_equal 3
    end
  end #add

  describe '#merge' do
    it 'adds the elements in the passed enumerable' do
      elements  = (1..20).map { |i| [score_for(i), i] }
      zset       = Tinto::SortedSet::RedisBackend.new(@storage_key)

      elements.size.must_equal 20
      zset.size.must_equal 0
      zset.merge elements
      zset.size.must_equal 20
    end
  end #merge

  describe '#delete' do
    it 'deletes an element from the zset' do
      zset = Tinto::SortedSet::RedisBackend.new(@storage_key)
      zset.add score_for(1), 1
      4.times { zset.delete 5 }
      zset.size.must_equal 1

      zset.delete 1
      zset.size.must_equal 0
    end
  end #delete

  describe '#clear' do
    it 'removes all elements' do
      zset = Tinto::SortedSet::RedisBackend.new(@storage_key)
      zset.add score_for(1), 1
      zset.clear
      zset.size.must_equal 0
    end
  end #clear

  def score_for(element)
    Time.now.to_f
  end
end # Tinto::SortedSet::RedisBackend

