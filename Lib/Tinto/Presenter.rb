# encoding: utf-8
require 'Tinto/Transformer'

module Tinto
  module Presenter
    def self.determine_for(resource)
      return Tinto::Presenter::Collection if resource.kind_of? Enumerable
      parts = resource.class.to_s.split("::")
      parts.pop
      parts.push "Presenter"

      klass = Object.const_get(parts.shift)

      while constant = parts.shift
        klass = klass.const_get(constant)
      end

      klass
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
      def initialize(collection, scope={})
        @collection = collection
        @scope      = scope
      end #initialize

      def as_poro
        collection.map do |member| 
          presenter_klass_for(member).new(member, scope).as_poro
        end
      end #as_poro

      def as_json(*args)
        as_poro.to_json(*args)
        #map { |i| i.to_json(*args) }.join(',')}]"
      end #as_json

      private

      attr_reader :collection, :scope

      def presenter_klass_for(member)
        @presenter_klass ||= Tinto::Presenter.determine_for(member)
      end #presenter
    end # Collection

  end # Presenter
end # Tinto
