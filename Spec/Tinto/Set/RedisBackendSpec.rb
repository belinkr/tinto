# encoding: utf-8
$:.unshift File.expand_path('../../../../Lib', __FILE__)
require 'minitest/autorun'
require 'ostruct'
require 'redis'
require_relative '../../../Lib/Tinto/Set/RedisBackend'

describe Tinto::Set::RedisBackend do 
  $redis ||= Redis.new
  $redis.select 8

  before do
    $redis.flushdb
    @storage_key = 'test'
  end
  
  describe '#initialize' do
    it 'requires a storage_key' do
      lambda { Tinto::Set::RedisBackend.new }.must_raise ArgumentError
      Tinto::Set::RedisBackend.new @storage_key
    end
  end #initialize

  describe '#fetch' do
    it 'gets all elements stored in the DB' do
      set = Tinto::Set::RedisBackend.new(@storage_key)
      set.add factory(id: 1)
      set.fetch.size.must_equal 1
    end
  end #fetch

  describe '#each' do
    it 'returns an enumerator if no block given' do
      set = Tinto::Set::RedisBackend.new(@storage_key)
      set.each.must_be_instance_of Enumerator
    end

    it 'yields the elements as strings' do
      set = Tinto::Set::RedisBackend.new(@storage_key)
      set.add factory(id: 1)
      set.each { |element| element.must_be_instance_of String }
    end
  end #each

  describe '#size' do
    it 'returns the number of elements in the set' do
      set = Tinto::Set::RedisBackend.new(@storage_key)
      set.add factory(id: 1)
      set.size.must_equal 1
    end
  end #size

  describe '#include?' do
    it 'returns true if the set includes the passed id' do
      set = Tinto::Set::RedisBackend.new(@storage_key)
      set.add factory(id: 1)
      set.include?('1').must_equal true
      set.include?(1).must_equal true
    end
  end #include?

  describe '#first' do
    it 'returns the first element in the set' do
      set = Tinto::Set::RedisBackend.new(@storage_key)
      set.add factory(id: 1)
      set.add factory(id: 2)
      set.first.must_equal '1'
    end
  end #first

  describe '#add' do
    it 'adds the id of a member to the set, if not included yet' do
      set = Tinto::Set::RedisBackend.new(@storage_key)
      set.add factory(id: 1)
      4.times { set.add factory(id: 2) }
      set.size.must_equal 2

      set.add factory(id: 3)
      set.size.must_equal 3
    end
  end #add

  describe '#merge' do
    it 'adds the elements in the passed enumerable' do
      elements  = (1..20).map { |i| factory(id: i) }
      set       = Tinto::Set::RedisBackend.new(@storage_key)

      elements.size.must_equal 20
      set.size.must_equal 0
      set.merge elements
      set.size.must_equal 20
    end
  end #merge

  describe '#delete' do
    it 'deletes an element from the set' do
      set = Tinto::Set::RedisBackend.new(@storage_key)
      set.add factory(id: 1)
      4.times { set.delete factory(id: 5) }
      set.size.must_equal 1

      set.delete factory(id: 1)
      set.size.must_equal 0
    end
  end #delete

  describe '#clear' do
    it 'removes all elements' do
      set = Tinto::Set::RedisBackend.new(@storage_key)
      set.add factory(id: 1)
      set.clear
      set.size.must_equal 0
    end
  end #clear

  describe '#union' do
    it 'returns a new set built by merging the set and the elements 
    of the given object, an enumerable or RedisBackend set' do
      set1 = Tinto::Set::RedisBackend.new 'test1'
      set1.add factory(id: 1)

      enumerable = ['2']
      (set1 | enumerable).size.must_equal 2
      enumerable = ['1']
      (set1 | enumerable).size.must_equal 1
      enumerable = []
      (set1 | enumerable).size.must_equal 1

      set2 = Tinto::Set::RedisBackend.new 'test2'
      set2.add factory(id: 1)
      (set1 | set2).size.must_equal 1
      set2.add factory(id: 2)
      (set1 | set2).size.must_equal 2
    end
  end

  def factory(attributes={})
    attributes.fetch :id
  end
end # Tinto::Set::RedisBackend

