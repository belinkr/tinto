# encoding: utf-8
require 'forwardable'
require 'Tinto/Set'

module Tinto
  class MasterCollection
    extend Forwardable

    def_delegators :@set, *Tinto::Set::INTERFACE

    def initialize(storage_key)
      @storage_key  = storage_key
      @set          = Tinto::Set.new self
    end #initialize

    def valid?
      true
    end

    def storage_key
      "#{@storage_key}/master"
    end
  end # MasterCollection
end # Tinto

