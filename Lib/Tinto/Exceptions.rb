# encoding: utf-8

module Tinto
  module Exceptions 
    class NotAllowed < RuntimeError; end
    class NotFound < RuntimeError; end
    class PersistenceError < RuntimeError; end
    class InvalidResource < RuntimeError; end
    class InvalidCollection < InvalidResource; end
    class InvalidMember < InvalidResource; end
  end # Exceptions
end # Tinto

