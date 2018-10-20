# frozen_string_literal: true

require 'set'
require 'mini_nrepl/nrepl/op'
require 'mini_nrepl/logging'

module MiniNrepl
  #
  # Simple wrapper around transport to bootstrap available ops and make them available
  # to be performed
  #
  class Nrepl
    Error = Class.new(StandardError)

    include Logging

    attr_reader :tt, :ops
    attr_accessor :session

    # @param transport [#send(Hash)] Transport
    def initialize(transport)
      logger.debug(self.class) { "Initializing with #{transport.inspect}" }
      @tt = transport
      @ops = {}
      inject_ops!
    end

    # Bootstraps available ops
    # @return [self]
    def inject_ops!
      logger.debug(self.class) { 'Injecting ops' }
      msg = describe(verbose: true).first
      msg.fetch('ops').each do |name, desc|
        @ops[name] = Op.new(name, desc)
      end
      self
    end

    # Performs given op
    # @param name [String]
    # @param args [Hash]
    def op(name, args = {}, &block)
      logger.debug(self.class) { "op #{name.inspect} #{args.inspect}" }

      check_op_available!(name)

      @ops[name].call(tt, args.merge(session: session), &block)
    end

    # Sends "describe" op to nrepl
    # @param verbose [Bool] Controls whether op descriptions will be available in the response
    def describe(verbose: true)
      logger.debug(self.class) { "Describe, verbose: #{verbose}" }
      op = { op: 'describe', 'verbose?': verbose.to_s }
      op[:session] = session if session
      tt.send(op)
    end

    # Initializes new session which will be used further
    # @param session [String] session-id
    def clone_session(session = nil)
      msg = op('clone', session: session).first
      self.session = msg.fetch('new-session')
    end

    private

    def check_op_available!(name)
      return if @ops.key?(name)

      logger.error(self.class) { "op #{name.inspect} not available" }
      raise Error, "Op #{name} is not available"
    end
  end
end
