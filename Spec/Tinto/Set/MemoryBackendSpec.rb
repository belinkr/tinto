# encoding: utf-8
$:.unshift File.expand_path('../../../../Lib', __FILE__)
require 'minitest/autorun'
require 'ostruct'
require_relative '../../../Lib/Tinto/Set/MemoryBackend'

describe Tinto::Set::MemoryBackend do 
  describe 'forwarded methods' do
    it 'delegates enumerable methods to the internal set' do
      set = Tinto::Set::MemoryBackend.new
      Tinto::Set::MemoryBackend::FORWARDED_METHODS.each do |method|
        set.must_respond_to method
      end
    end
  end # forwarded methods
  
  describe '#include?' do
    it 'returns true if set includes the string equivalent of the passed id' do
      set = Tinto::Set::MemoryBackend.new
      set.add factory(id: 1)
      set.include?(1).must_equal true
      set.include?('1').must_equal true
    end
  end

  describe '#add' do
    it 'adds the id of a member to the collection, if not included yet' do
      set = Tinto::Set::MemoryBackend.new
      set.add factory(id: 1)
      4.times { set.add factory(id: 2) }
      set.size.must_equal 2

      set.add(factory(id: 3))
      set.size.must_equal 3
    end

    it 'stores the ids as strings' do
      set = Tinto::Set::MemoryBackend.new
      set.add factory(id: 1)
      set.include?(1).must_equal true
      set.include?('1').must_equal true
    end
  end #add

  describe '#merge' do
    it 'adds the elements in the passed enumerable' do
      elements  = (1..20).map { |i| factory(id: i) }
      set       = Tinto::Set::MemoryBackend.new

      elements.size.must_equal 20
      set.size.must_equal 0
      set.merge(elements)
      set.size.must_equal 20
    end

    it 'stores the ids as strings' do
      set = Tinto::Set::MemoryBackend.new
      set.merge [factory(id: 1)]
      set.include?(1).must_equal true
      set.include?('1').must_equal true
    end
  end #merge

  describe '#delete' do
    it 'deletes the equivalent string element from the collection' do
      set = Tinto::Set::MemoryBackend.new
      set.add factory(id: 1)
      set.size.must_equal 1

      set.delete(factory(id: 1))
      set.size.must_equal 0

      set.add(factory(id: '1'))
      set.delete(factory(id: '1'))
      set.size.must_equal 0
    end
  end #delete

  describe '#|' do
    it 'returns a new set built by merging the set and the elements 
    of the given enumerable object' do
      set = Tinto::Set::MemoryBackend.new
      set.add factory(id: 1)
      enumerable = ['2']

      (set | enumerable).size.must_equal 2

      enumerable = ['1']
      (set | enumerable).size.must_equal 1

      enumerable = []
      (set | enumerable).size.must_equal 1
    end
  end #union

  def factory(attributes)
    attributes.fetch :id
  end
end # Tinto::Set::MemoryBackend

