# encoding: utf-8
$:.unshift File.expand_path('../../../Lib', __FILE__)
require 'minitest/autorun'
require 'redis'
require 'ostruct'
require 'uuidtools'
require_relative '../../Lib/Tinto/Member'
require_relative '../../Lib/Tinto/Exceptions'

include Tinto::Exceptions

describe Tinto::Member do
  $redis ||= Redis.new
  $redis.select 8

  before {
    $redis.flushdb
    class OpenStruct
      def to_json
        self.attributes.to_json
      end
    end
  }
  after {
  }

  describe '#initialize' do
    it 'requires a member resource' do
      lambda { Tinto::Member.new }.must_raise ArgumentError
      Tinto::Member.new OpenStruct.new
    end

    it 'sets a default value for the created_at attribute of the resource' do
      resource  = OpenStruct.new
      member    = Tinto::Member.new resource

      resource.created_at.wont_be_nil
    end

    it 'sets a default value for the updated_at attribute of the resource' do
      member = Tinto::Member.new OpenStruct.new
      (member.score > 0.0).must_equal true
    end

    it 'sets a default UUID for the resource' do
      resource  = OpenStruct.new
      member    = Tinto::Member.new resource
      UUIDTools::UUID.parse(resource.id).valid?.must_equal true
    end

    it 'accepts a default context for validation' do
      resource  = OpenStruct.new
      def resource.valid?(context=nil); context == 'workspace'; end

      member    = Tinto::Member.new resource, 'foo'
      lambda { member.validate! }.must_raise InvalidMember

      member    = Tinto::Member.new resource, 'workspace'
      member.validate!
    end
  end #initialize

  describe '#validate!' do
    it 'raises if resource invalid' do
      resource  = OpenStruct.new
      member    = Tinto::Member.new resource, 'foo'

      def resource.valid?(*args); false; end
      lambda { member.validate! }.must_raise InvalidMember

      def resource.valid?(*args); true; end
      member.validate!
    end

    it 'validates in context if passed at initialization' do
      resource  = OpenStruct.new
      def resource.valid?(context=nil); context =='workspace'; end

      member    = Tinto::Member.new resource, 'foo'
      lambda { member.validate! }.must_raise InvalidMember

      member    = Tinto::Member.new resource, 'workspace'
      member.validate!
    end
  end #validate!

  describe '#attributes' do
    it 'delegates to the member resource attributes' do
      resource1 = factory(name: 'member 1')
      member1   = Tinto::Member.new resource1

      resource1.attributes.must_equal member1.attributes
    end
  end #attributes

  describe '#==' do
    it 'compares the #attributes values of the resource' do
      resource1 = factory(name: 'test')
      member1   = Tinto::Member.new resource1
      resource2 = factory(name: 'test', id: resource1.id)
      member2   = Tinto::Member.new resource2
      member1.must_equal member2
    end
  end #==

  describe '#score' do
    it 'returns the float value of the updated_at attribute' do
      just_now  = Time.now
      member    = Tinto::Member.new factory(name: 'test', updated_at: just_now)

      member.score.must_equal just_now.to_f
    end

    it 'returns -1.0 if resource has no updated_at attribute' do
      resource  = factory(name: 'test')
      member    = Tinto::Member.new resource
      resource.updated_at = nil
      member.score.must_equal Tinto::Member::NO_SCORE_VALUE
    end
  end #score

  describe '#to_json' do
    it 'returns a JSON representation of the resource' do
      resource  = factory(name: 'test')
      member    = Tinto::Member.new resource
      JSON.parse(member.to_json).fetch('id').must_equal resource.id
    end
  end #to_json

  describe '#fetch' do
    it 'retrieves resource data from the DB' do
      member = Tinto::Member.new factory(name: 'test')
      member.sync
      id = member.attributes.fetch :id

      member = Tinto::Member.new factory(id: id)
      member.fetch
      member.attributes.fetch('name').must_equal 'test'
    end

    it 'raises NotFound if key empty' do
      lambda { member = Tinto::Member.new(factory(id: 55)).fetch }
        .must_raise Tinto::Exceptions::NotFound
    end
  end #fetch

  describe '#sync' do
    it 'persists changes to the member' do
      resource  = factory(name: 'test')
      member    = Tinto::Member.new resource
      member.sync

      attributes = Tinto::Member.new(resource).fetch.attributes
      attributes.fetch('name').must_equal 'test'
    end

    it 'raises InvalidMember unless resource valid' do
      resource  = factory(name: 'test')
      member    = Tinto::Member.new resource
      def resource.valid?(*args); false; end

      lambda { member.sync }.must_raise InvalidMember
    end

    it 'stores the resource in a unique key' do
      resource1 = factory(name: 'resource 1')
      resource2 = factory(name: 'resource 2')
      member1   = Tinto::Member.new resource1
      member2   = Tinto::Member.new resource2

      resource1.storage_key.must_equal resource2.storage_key

      member1.sync
      member2.sync

      member1.fetch
      member1.attributes.fetch('name').must_equal 'resource 1'

      member2.fetch
      member2.attributes.fetch('name').must_equal 'resource 2'
    end
  end #sync

  describe '#update' do
    it 'updates a member with the whitelisted attributes of another' do
      OpenStruct.const_set 'WHITELIST', %w{ name }
      changes   = { name: 'test', entity_id: 5 }
      resource  = factory()
      member    = Tinto::Member.new resource

      member.update(changes)
      member.attributes.fetch(:name).must_equal 'test'
      member.attributes.fetch(:entity_id, 'unchanged').must_equal 'unchanged'
      OpenStruct.send :remove_const, :'WHITELIST'
    end

    it 'refreshes the updated_at timestap' do
      changes   = factory(name: 'test', entity_id: 5)
      resource  = factory()
      member    = Tinto::Member.new resource

      previous_updated_at = resource.updated_at
      sleep(1.0/1000.0)
      member.update(changes)
      resource.updated_at.to_f.wont_equal previous_updated_at.to_f
    end
  end #update

  describe '#delete' do
    it 'marks the resource as deleted' do
      member = Tinto::Member.new factory(name: 'test')
      member.attributes[:deleted_at].must_be_nil
      member.delete
      member.attributes[:deleted_at].must_be_instance_of Time
    end

    it 'raises InvalidMember unless resource valid' do
      resource  = factory(name: 'test')
      member    = Tinto::Member.new resource
      def resource.valid?(*args); false; end

      lambda { member.delete }.must_raise InvalidMember
    end
  end #delete

  describe '#undelete' do
    it 'marks the resource as not deleted' do
      member = Tinto::Member.new factory(name: 'test')
      member.delete
      member.attributes[:deleted_at].must_be_instance_of Time
      member.undelete
      member.attributes[:deleted_at].must_be_nil
    end

    it 'raises InvalidMember if resource is not marked as deleted' do
      member = Tinto::Member.new factory(name: 'test')
      lambda { member.undelete }.must_raise InvalidMember
    end

    it 'raises InvalidMember unless resource valid' do
      resource  = factory(name: 'test')
      member    = Tinto::Member.new resource

      member.delete
      def resource.valid?(*args); false; end

      lambda { member.undelete }.must_raise InvalidMember
    end
  end #undelete

  describe '#destroy' do
    it 'removes the element from the db' do
      resource  = factory(name: 'test')
      member    = Tinto::Member.new resource
      member.sync

      id        = resource.id
      member.destroy

      resource  = factory(id: id, name: 'test')
      lambda { Tinto::Member.new(resource).fetch }
        .must_raise Tinto::Exceptions::NotFound
    end

    it 'nilifies all attributes' do
      resource  = factory(name: 'test')
      member    = Tinto::Member.new resource

      member.destroy
      resource.attributes.keys.each { |k| resource.send(k).must_be_nil }
    end
  end #destroy

  describe '#deleted?' do
    it 'returns true if resource is deleted' do
      resource  = factory(name: 'test')
      member    = Tinto::Member.new resource

      member.deleted?.must_equal false
      member.delete
      member.deleted?.must_equal true
    end
  end #deleted?

  describe '#whitelist' do
    it 'removes non-whitelisted attributes from the passed hash' do
      OpenStruct.const_set :'WHITELIST', %w{ name }
      resource  = factory(name: 'resource 1')
      member    = Tinto::Member.new resource

      whitelisted = member.whitelist(name: 'resource 1', entity_id: 3)
      whitelisted.must_equal({ name: 'resource 1' })
      OpenStruct.send :remove_const, :'WHITELIST'
    end
  end #whitelist

  def factory(attributes={})
    member = OpenStruct.new(attributes)
    def member.valid?(*args); true; end
    def member.attributes; self.marshal_dump; end
    def member.storage_key; 'test'; end
    def member.attributes=(attributes={}); self.marshal_load attributes; end
    member
  end
end # Tinto::Member

