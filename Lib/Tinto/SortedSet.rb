# encoding: utf-8
require 'Tinto/Exceptions'
require 'Tinto/SortedSet/MemoryBackend'
require 'Tinto/SortedSet/RedisBackend'

module Tinto
  class SortedSet
    include Tinto::Exceptions
    include Enumerable

    NOT_IN_SET_SCORE  = -1.0
    INTERFACE         = %w{ validate! sync synced? page fetch reset each size
                            length empty? exists? include? add merge delete 
                            clear score } 

    def initialize(collection)
      @collection       = collection
      @buffered_zset    = MemoryBackend.new
      @persisted_zset   = RedisBackend.new @collection.storage_key
      @current_backend  = @persisted_zset
      @backlog          = []
    end #initialize

    def validate!
      raise InvalidCollection unless @collection.valid?
    end #validate!

    def in_memory?
      validate!
      @current_backend == @buffered_zset
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
      page_number, per_page = page_number.to_i, per_page.to_i
      from = page_number * per_page
      to   = from + per_page - 1

      fetch(from, to)
      @collection
    end #page

    def fetch(from=0, to=-1)
      validate!
      @backlog.clear
      @buffered_zset.clear
      @buffered_zset.merge @persisted_zset.fetch(from, to)
      @current_backend  = @buffered_zset
      @collection
    end #fetch

    def reset(members=[])
      validate!
      @backlog.clear
      @current_backend  = @buffered_zset
      clear
      merge members
      @collection
    end #reset

    def score(member)
      @current_backend.score(member.id.to_s) || NOT_IN_SET_SCORE
    end #score

    def each
      validate!
      fetch unless in_memory?
      return Enumerator.new(self, :each) unless block_given?
      @buffered_zset.each do |score, id| 
        yield @collection.instantiate_member(id: id).fetch
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
      score     = score_for(member)
      @buffered_zset.add score, member_id
      @backlog.push(lambda { @persisted_zset.add score, member_id })
      @collection
    end #add

    def merge(members)
      validate!
      scores_and_member_ids = scores_and_member_ids_for(members)
      @buffered_zset.merge scores_and_member_ids
      @backlog.push(lambda { @persisted_zset.merge scores_and_member_ids })
      @collection
    end #merge

    def delete(member)
      validate!
      member.validate!
      member_id = member.id.to_s
      @buffered_zset.delete member_id
      @backlog.push(lambda { @persisted_zset.delete member_id })
      @collection
    end #delete

    def clear
      validate!
      @buffered_zset.clear
      @backlog.push(lambda { @persisted_zset.clear })
      @collection
    end #clear

    def score_for(member)
      member.updated_at.to_f
    end #score_for

    def scores_and_member_ids_for(members)
      members.map do |member|
        member.validate!
        [score_for(member), member.id.to_s]
      end
    end #scores_and_member_ids_for
  end # SortedSet
end # Tinto
