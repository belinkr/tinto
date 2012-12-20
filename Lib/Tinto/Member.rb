# encoding: utf-8
require 'json'
require 'uuidtools'
require 'Tinto/Exceptions'

module Tinto
  class Member
    include Tinto::Exceptions

    NO_SCORE_VALUE = -1.0
    INTERFACE      = %w{ validate! to_hash == score to_json fetch
                         sync update delete undelete destroy sanitize 
                         deleted? }

    def initialize(resource, context=nil)
      @resource             = resource
      @context              = context
      resource.id          ||= UUIDTools::UUID.timestamp_create.to_s
      resource.created_at  ||= Time.now
      resource.updated_at  ||= Time.now
    end #initialize

    def validate!
      raise InvalidMember unless validated? && identified?
      resource
    end #validate!

    def attributes
      resource.attributes
    end #attributes

    alias_method :to_hash, :attributes

    def ==(other)
      attributes.to_s == other.attributes.to_s
    end #==

    def score
      (resource.updated_at || NO_SCORE_VALUE).to_f
    end #score

    def to_json(*args)
      attributes.to_json(*args)
    end #to_json

    def fetch
      resource.attributes = JSON.parse($redis.get storage_key)
      resource
    rescue TypeError
      raise NotFound
    end #fetch

    def sync
      validate!
      $redis.set storage_key, self.to_json
      resource
    end #sync

    def update(attributes={})
      whitelist(attributes).each { |k, v| resource.send :"#{k}=", v }
      resource.updated_at = Time.now
      resource
    end #update

    def delete
      validate!
      resource.deleted_at = Time.now
      resource
    end #delete

    def undelete
      validate!
      raise InvalidMember unless resource.deleted_at.respond_to? :utc
      resource.deleted_at = nil
      resource
    end #undelete

    def destroy
      $redis.del storage_key
      resource.attributes.keys.each { |k| resource.send :"#{k}=", nil }
      resource
    end #destroy

    def deleted?
      !!resource.deleted_at
    end #deleted?

    def whitelist(attributes={})
      return attributes unless resource.class.const_defined?(:'WHITELIST')
      whitelist = resource.class.const_get(:'WHITELIST')
      attributes.select { |k, v| [k, v] if whitelist.include? k.to_s }
    end #whitelist

    private

    def validated?
      return resource.valid?(context) if context
      return resource.valid?
    end #validated?

    def identified?
      UUIDTools::UUID.parse(resource.id).valid?
    end #identified?

    def storage_key
      "#{resource.storage_key}:#{resource.id}"
    end #storage_key

    attr_reader :resource, :context
  end # Member
end # Tinto

