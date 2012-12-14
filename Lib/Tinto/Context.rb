# encoding: utf-8
module Tinto
  module Context
    def syncables
      @syncables ||= []
    end

    def sync
      $redis.multi { syncables.each(&:sync) }
    end #sync

    def run
      call
      sync
    end #run
    
    private

    def will_sync(*syncables)
      @syncables = syncables
    end
  end # Context
end # Tinto

