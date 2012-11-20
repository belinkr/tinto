# encoding: utf-8
require 'Tinto/Exceptions'
require 'Tinto/Set/MemoryBackend'
require 'Tinto/Set/RedisBackend'

module Tinto
  class Set
    include Enumerable
    include Tinto::Exceptions

    INTERFACE = %w{ validate! in_memory? sync synced? page fetch reset each 
                    size length empty? exists? include? first add merge delete
                    clear first }

    def initialize(collection)
      @collection       = collection
      @buffered_set     = MemoryBackend.new
      @persisted_set    = RedisBackend.new @collection.storage_key
      @current_backend  = @persisted_set
      @backlog          = []
    end #initialize

    def storage_key
      @persisted_set.storage_key
    end #storage_key

    def validate!
      raise InvalidCollection unless @collection.valid?
    end #validate!

    def in_memory?
      validate!
      @current_backend == @buffered_set
    end #in_memory?

    def sync
      validate!
      $redis.pipelined { @backlog.each { |command| command.call } }
      @backlog.clear
      @collection
    end #sync

    def synced?
      validate!
      @backlog.empty?
    end #synced?

    def page(page_number=0, per_page=20)
      validate!
      fetch

      page_number, per_page = page_number.to_i, per_page.to_i
      from = page_number * per_page
      to   = from + per_page - 1

      elements          = @buffered_set.to_a.slice(from..to)
      @buffered_set.clear.merge elements
      @current_backend  = @buffered_set
      @collection
    end #page

    def fetch
      validate!
      @backlog.clear
      @buffered_set.clear
      @buffered_set.merge @persisted_set.fetch
      @current_backend  = @buffered_set
      @collection
    end #fetch

    def reset(members=[])
      validate!
      @backlog.clear
      @current_backend  = @buffered_set
      clear
      merge members
      @collection
    end #reset

    def each
      validate!
      fetch unless in_memory?
      return Enumerator.new(self, :each) unless block_given?
      @buffered_set.each do |id| 
        yield @collection.instantiate_member(id: id)
      end
    end #each

    def size
      validate!
      @current_backend.size
    end #size

    alias_method :length, :size

    def empty?
      !(size.to_i > 0)
    end #empty?

    def include?(member)
      validate!
      @current_backend.include? member.id.to_s
    end

    def first
      validate!
      @collection.instantiate_member(id: @current_backend.first)
    end

    def add(member)
      validate!
      member.validate!
      member_id = member.id.to_s
      @buffered_set.add member_id
      @backlog.push(lambda { @persisted_set.add member_id })
      @collection
    end #add

    def merge(members)
      validate!
      member_ids = members.map { |member|
        member.validate!
        member.id.to_s
      }
      @buffered_set.merge member_ids
      @backlog.push(lambda { @persisted_set.merge member_ids })
      @collection
    end #merge

    def delete(member)
      validate!
      member.validate!
      member_id = member.id.to_s
      @buffered_set.delete member_id
      @backlog.push(lambda { @persisted_set.delete member_id })
      @collection
    end #delete

    def clear
      validate!
      @buffered_set.clear
      @backlog.push(lambda { @persisted_set.clear })
      @collection
    end #clear

    def |(enumerable_or_redis_backed_set)
      @current_backend | enumerable_or_redis_backed_set
    end

    alias_method :union, :|

  end # Set
end # Tinto
