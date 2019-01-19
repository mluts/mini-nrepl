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

    # Default session-id storage
    # We have to preserve same session-id, so let's store it in current directory
    module SessionStorage
      module_function

      FNAME = '.mini-nrepl'

      def write!(session_id)
        Logging.logger.debug(self) { "Storing session-id #{session_id}" }
        IO.write(FNAME, session_id.to_s.strip)
      end

      def read
        Logging.logger.debug(self) { 'Reading session-id' }
        IO.read(FNAME) if File.exist?(FNAME) && !File.empty?(FNAME)
      end
    end

    # @param transport [#send(Hash)] Transport
    def initialize(transport, store_session: true, session_storage: SessionStorage)
      logger.debug(self.class) { "Initializing with #{transport.inspect}" }
      @tt = transport
      @ops = {}
      @session_storage = session_storage
      inject_ops!
      set_session! if store_session
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
      msg.fetch('new-session').tap do |sid|
        self.session = sid
      end
    end

    def set_session!
      logger.debug(self.class) { 'Setting session-id' }
      sid = @session_storage.read

      if !sid.nil? && known_sessions.include?(sid)
        logger.debug(self.class) { "Setting known session-id #{sid.inspect}" }
        self.session = sid
      else
        logger.debug(self.class) { 'Cloning session' }
        sid = clone_session
        @session_storage.write!(sid)
      end
    end

    private

    def known_sessions
      op('ls-sessions').reduce(:merge).fetch('sessions', []).tap do |sessions|
        logger.debug(self.class) { "Known sessions: #{sessions.inspect}" }
      end
    end

    def check_op_available!(name)
      return if @ops.key?(name)

      logger.error(self.class) { "op #{name.inspect} not available" }
      raise Error, "Op #{name} is not available"
    end
  end
end
