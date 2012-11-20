# encoding: utf-8
require 'Tinto/Transformer'

module Tinto
  module Presenter
    def self.determine_for(resource)
      return Tinto::Presenter::Collection if resource.kind_of? Enumerable
      chains = resource.class.to_s.split("::")
      chains.pop
      chains.push "Presenter"

      klass = Object.const_get(chains.shift)
      while const = chains.shift
        klass = klass.const_get(const)
      end

      klass
    rescue NameError
      false
    end

    def self.timestamps_for(resource)
      timestamps = {}

      if resource.created_at
        timestamps.merge!(created_at: resource.created_at.iso8601)
      end

      if resource.updated_at
        timestamps.merge!(updated_at: resource.updated_at.iso8601)
      end

      if resource.deleted_at
        timestamps.merge!(deleted_at: resource.deleted_at.iso8601)
      end

      if resource.respond_to?(:rejected_at) && resource.rejected_at
        timestamps.merge!(rejected_at: resource.rejected_at.iso8601)
      end

      timestamps
    end

    def self.errors_for(resource)
      return  {} if resource.errors.empty?
      return  { errors: resource.errors.flat_map { |set| 
                          set.map { |error| error.to_s }
                        } 
              }
    end

    class Collection
      def initialize(collection, actor=nil)
        @collection = collection
        @actor      = actor
      end

      def as_poro
        @collection.map { |member|
          member.fetch
          unless member.deleted_at
            member_presenter.new(member, @actor).as_poro 
          end
        }
      end

      def as_json
        "[#{as_poro.map { |i| i.to_json }.join(',')}]"
      end

      def member_presenter
        return false unless @collection.length > 0
        Tinto::Presenter.determine_for(@collection.first)
      end
    end # Collection
  end # Presenter
end # Tinto
