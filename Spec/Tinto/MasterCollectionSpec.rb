# encoding: utf-8
$:.unshift File.expand_path('../../../Lib', __FILE__)
require 'minitest/autorun'
require 'redis'
require_relative '../../Lib/Tinto/MasterCollection'

$redis ||= Redis.new
$redis.select 8

describe Tinto::MasterCollection do
  before { $redis.flushdb }

  describe '#initialize' do
    it 'takes a storage_key' do
      lambda { Tinto::MasterCollection.new }.must_raise ArgumentError
    end
  end #initialize

  describe '#valid?' do
    it 'is always true' do
      Tinto::MasterCollection.new('test_key').valid?.must_equal true
    end
  end #valid?

  describe '#storage_key' do
    it 'returns a master key' do
      Tinto::MasterCollection.new('test').storage_key.must_match /master/
    end
  end #storage_key

  describe 'delegation' do
    it 'implements the Tinto::Set interface' do
      master = Tinto::MasterCollection.new('test')
    
      Tinto::Set::INTERFACE.each do |method| 
        master.respond_to?(method).must_equal true
      end
    end
  end # delegation
end # Tinto::MasterCollection

