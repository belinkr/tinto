# encoding: utf-8
require 'Tinto/Presenter'

module Tinto
  class IndexScheduler
    QueueKey = 'elasticsearch'

    def initialize(resource)
      @resource = resource
    end

    def schedule
      $redis.rpush QueueKey, document
    end

    def document
      presenter_for(@resource).new(@resource).as_poro.merge(
        '_index'      => @resource.index,
        '_index_path' => @resource.index_path
      ).to_json
    end

    private

    def presenter_for(resource)
      Tinto::Presenter.determine_for(resource)
    end
  end # IndexScheduler
end # Tinto

