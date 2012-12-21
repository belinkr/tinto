# encoding: utf-8
$:.unshift File.expand_path('../../../Lib', __FILE__)
require 'minitest/autorun'
require 'ostruct'
require 'redis'
require_relative '../../Lib/Tinto/SortedSet'
require_relative '../../Lib/Tinto/Exceptions'

include Tinto::Exceptions

describe Tinto::SortedSet do
  $redis ||= Redis.new
  $redis.select 8

  before do
    $redis.flushdb
    @collection = OpenStruct.new(storage_key: 'test:key')
    def @collection.valid?; true; end
    def @collection.instantiate_member(attrs={}); 
      member = OpenStruct.new(attrs)
      def member.fetch; self; end
      member
    end
  end

  describe '#initialize' do
    it 'requires a collection object' do
      lambda { Tinto::SortedSet.new }.must_raise ArgumentError
      Tinto::SortedSet.new OpenStruct.new
    end
  end #initialize

  describe 'when collection is invalid' do
    it 'raises InvalidCollection in all methods' do
      zset = Tinto::SortedSet.new(@collection)

      def @collection.valid?; false; end
      lambda { zset.each }.must_raise InvalidCollection

      def @collection.valid?; true; end
      zset.each
    end
  end # when collection is invalid

  describe '#sync' do
    it 'persists changes to the set' do
      zset = Tinto::SortedSet.new(@collection)
      zset.add factory(id: 1)
      zset.sync
      zset.size.must_equal 1

      zset = Tinto::SortedSet.new(@collection)
      zset.fetch
      zset.size.must_equal 1
    end
  end #sync

  describe '#synced?' do
    it 'returns true if no backlog commands pending' do
      zset = Tinto::SortedSet.new(@collection)
      zset.synced?.must_equal true
      zset.add factory(id: 1)
      zset.synced?.must_equal false
      zset.sync
      zset.synced?.must_equal true
    end
  end #synced?

  describe '#fetch' do
    it 'loads all records from db' do
      elements  = (1..100).map { |i| factory(id: i) }
      zset      = Tinto::SortedSet.new(@collection)
      zset.reset(elements)
      zset.sync

      zset      = Tinto::SortedSet.new(@collection)
      zset.fetch

      def $redis.zcard(*args); $redis_called = true; super *args; end
      $redis_called = false
      zset.size.must_equal 100
      $redis_called.must_equal false
    end
  end #fetch

  describe '#page' do
    it 'loads a page of records' do
      elements  = (1..100).map { |i| factory(id: i) }
      zset      = Tinto::SortedSet.new(@collection)
      zset.reset(elements)
      zset.sync

      zset      = Tinto::SortedSet.new(@collection)
      zset.page

      def $redis.zcard(*args); $redis_called = true; super *args; end
      $redis_called = false
      zset.size.must_equal 20
      $redis_called.must_equal false

      zset.page(1)
      zset.size.must_equal 20
      zset.page(2)
      zset.size.must_equal 20
    end

    it 'loads the highest scored records first' do
      elements  = (1..100).map { |i| factory(id: i) }
      zset      = Tinto::SortedSet.new(@collection)
      zset.reset(elements)
      zset.sync

      zset      = Tinto::SortedSet.new(@collection)
      zset.page
      last_score_in_first_page  = zset.score(zset.to_a[19])

      zset.page(1)
      first_score_in_second_page  = zset.score(zset.to_a[0])
      (last_score_in_first_page > first_score_in_second_page).must_equal true
    end
  end #page

  describe '#reset' do
    it 'populates the set with the passed members' do
      zset = Tinto::SortedSet.new(@collection)
      zset.reset [factory(id: 3)]
      zset.map.to_a.first.must_be_instance_of OpenStruct
      zset.map.to_a.first.id.must_equal '3'
    end

    it 'schedules the reset command for syncing' do
      zset = Tinto::SortedSet.new(@collection)
      zset.synced?.must_equal true
      zset.reset([factory(id: 3)])
      zset.synced?.must_equal false
    end

    it 'allows to work with the zset off the database' do
      zset          = Tinto::SortedSet.new(@collection)
      zset.reset
      def zset.sync; $sync_called = true; super; end

      $sync_called  = false
      zset.add factory(id: 55)
      zset.size.must_equal 1
      $sync_called.must_equal false
      zset.sync
      $sync_called.must_equal true
      zset.size.must_equal 1
    end

    it 'raises unless passed an Enumerable' do
      zset = Tinto::SortedSet.new(@collection)
      lambda { zset.reset(OpenStruct.new) }.must_raise NoMethodError
    end
  end #reset

  describe '#each' do
    it 'returns an enumerator if no block given' do
      zset = Tinto::SortedSet.new(@collection)
      zset.each.must_be_instance_of Enumerator
    end

    it 'yields instances of the member class' do
      zset = Tinto::SortedSet.new(@collection)
      zset.reset([factory(id: 1)])
      zset.each do |element|
        element     .must_be_instance_of OpenStruct
        element.id  .must_be_instance_of String
      end
    end
  end #each 

  describe '#size' do
    it 'returns the number of elements in the set' do
      zset = Tinto::SortedSet.new(@collection)
      zset.reset([factory(id: 1)])
      zset.size.must_equal 1
    end
  end #size

  describe '#empty?' do
    it 'is true if the collection has no elements' do
      zset = Tinto::SortedSet.new(@collection)
      zset.reset
      zset.add factory(id: 1)
      zset.empty?.must_equal false

      empty_zset = Tinto::SortedSet.new(@collection)
      empty_zset.reset
      empty_zset.add factory(id: 1)
      empty_zset.delete factory(id: 1)
      empty_zset.empty?.must_equal true
      empty_zset.sync

      empty_zset = Tinto::SortedSet.new(@collection)
      empty_zset.empty?.must_equal true
    end
  end #empty?

  describe '#include?' do
    it 'returns true if the set includes the id of the passed object' do
      zset = Tinto::SortedSet.new(@collection)
      zset.reset
      zset.add factory(id: 1)
      zset.include?(factory(id: 1)).must_equal true
      zset.include?(factory(id: 2)).must_equal false
    end
  end #include?

  describe '#add' do
    it 'adds the id of a member to the collection, if not included yet' do
      zset = Tinto::SortedSet.new(@collection)
      zset.reset([factory(id: 1)])
      4.times { zset.add factory(id: 2) }
      zset.size.must_equal 2

      zset.add factory(id: 3)
      zset.size.must_equal 3
    end

    it 'sets the score as the updated_at field of the passed member' do
      zset    = Tinto::SortedSet.new(@collection)
      zset.reset
      element = factory(id: 1)
      zset.add element
      zset.score(element).must_equal element.updated_at.to_f
    end

    it 'updates the score of an existing element' do
      element             = factory(id: 1)
      zset                = Tinto::SortedSet.new(@collection)
      zset.reset([element])
      previous_score      = zset.score(element)
      element.updated_at  = Time.now
      sleep(1.0/1000.0)
      zset.add(element)
      (zset.score(element).to_f > previous_score.to_f).must_equal true
    end

    it 'verifies the member' do
      zset     = Tinto::SortedSet.new(@collection)
      element = factory(id: 5)

      def element.validate!; raise InvalidMember; end
      lambda { zset.add(element) }.must_raise InvalidMember
    end
  end #add

  describe '#merge' do
    it 'adds the elements in the passed enumerable' do
      elements  = (1..20).map { |i| factory(id: i) }
      zset      = Tinto::SortedSet.new(@collection)
      zset.reset

      elements.size.must_equal 20
      zset.size.must_equal 0
      zset.merge(elements)
      zset.size.must_equal 20
    end
  end #merge

  describe '#delete' do
    it 'removes an element from the collection' do
      element = factory(id: 1)
      zset    = Tinto::SortedSet.new(@collection)
      zset.reset
      zset.add element
      4.times { zset.delete(factory(id: 5)) }
      zset.size.must_equal 1

      zset.delete(factory(id: 1))
      zset.size.must_equal 0
      zset.score(element).must_equal Tinto::SortedSet::NOT_IN_SET_SCORE
    end

    it 'verifies the member' do
      zset     = Tinto::SortedSet.new(@collection)
      element = factory(id: 5)

      def element.validate!; raise InvalidMember; end
      lambda { zset.delete(element) }.must_raise InvalidMember
    end
  end #delete

  describe '#clear' do
    it 'removes all members' do
      element = factory(id: 1)
      zset    = Tinto::SortedSet.new(@collection)
      zset.reset([element])
      zset.clear
      zset.size.must_equal 0
      zset.score(element).must_equal Tinto::SortedSet::NOT_IN_SET_SCORE
    end
  end #clear

  describe '#score' do
    it 'gets the score of an element' do
      element = factory(id: 1)
      zset    = Tinto::SortedSet.new(@collection)
      zset.reset
      zset.add element
      zset.score(element).must_equal element.updated_at.to_f
    end
  end

  def factory(attributes={})
    attributes  = { updated_at: Time.now }.merge!(attributes)
    member      = OpenStruct.new(attributes)
    def member.valid?; true; end
    member
  end
end
