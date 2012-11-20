# encoding: utf-8
$:.unshift File.expand_path('../../../../Lib', __FILE__)
require 'minitest/autorun'
require 'ostruct'
require_relative '../../../Lib/Tinto/SortedSet/MemoryBackend'

describe Tinto::SortedSet::MemoryBackend do 
  describe 'forwarded methods' do
    it 'delegates enumerable methods to the internal zset' do
      zset = Tinto::SortedSet::MemoryBackend.new
      Tinto::SortedSet::MemoryBackend::FORWARDED_METHODS.each do |method|
        zset.must_respond_to method
      end
    end
  end # forwarded methods
  
  describe '#include?' do
    it 'returns true if zset includes the string equivalent of the passed id' do
      zset = Tinto::SortedSet::MemoryBackend.new
      zset.add score_for(1), 1
      zset.include?(1).must_equal true
      zset.include?('1').must_equal true
    end
  end

  describe '#add' do
    it 'adds the id of a member to the collection, if not included yet' do
      zset = Tinto::SortedSet::MemoryBackend.new
      zset.add score_for(1), 1
      4.times { zset.add score_for(2), 2 }
      zset.size.must_equal 2

      zset.add score_for(3), 3
      zset.size.must_equal 3
    end

    it 'stores the ids as strings' do
      zset = Tinto::SortedSet::MemoryBackend.new
      zset.add score_for(1), 1
      zset.include?(1).must_equal true
      zset.include?('1').must_equal true
    end
  end #add

  describe '#merge' do
    it 'adds the elements in the passed enumerable' do
      elements  = (1..20).map { |i| [score_for(i), i] }
      zset      = Tinto::SortedSet::MemoryBackend.new

      elements.size.must_equal 20
      zset.size.must_equal 0
      zset.merge(elements)
      zset.size.must_equal 20
    end

    it 'stores the ids as strings' do
      elements  = (1..20).map { |i| [score_for(i), i] }
      zset      = Tinto::SortedSet::MemoryBackend.new
      zset.merge elements
      zset.include?(1).must_equal true
      zset.include?('1').must_equal true
    end
  end #merge

  describe '#delete' do
    it 'deletes the equivalent string element from the collection' do
      zset = Tinto::SortedSet::MemoryBackend.new
      zset.add score_for(1), 1
      zset.size.must_equal 1

      zset.delete 1
      zset.size.must_equal 0

      zset.add score_for(1), 1
      zset.delete 1
      zset.size.must_equal 0
    end
  end #delete

  describe '#clear' do
    it 'clears the elements' do
      zset = Tinto::SortedSet::MemoryBackend.new
      zset.add score_for(1), 1
      zset.size.must_equal 1
      zset.clear
      zset.size.must_equal 0
    end

    it 'clears the scores' do
      zset = Tinto::SortedSet::MemoryBackend.new
      zset.add score_for(1), 1
      (zset.score(1) > 0.0).must_equal true
      zset.clear
      zset.score(1).must_be_nil
    end
  end #clear

  def score_for(element)
    Time.now.to_f
  end
end # Tinto::SortedSet::MemoryBackend

