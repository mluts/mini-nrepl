# frozen_string_literal: true

require 'mini_nrepl/version'
require 'socket'
require 'mini_nrepl/bencode_transport_builder'
require 'mini_nrepl/nrepl'
require 'mini_nrepl/logging'

# Base module for gem
module MiniNrepl
  Error = Class.new(StandardError)

  # Exception which signals that nrepl op is not available
  class OpNotAvailable < Error
    def initialize(name)
      super("Op #{name.inspect} not available")
    end
  end

  extend Logging

  class << self
    def parse_addr(str)
      host, port = str.split(':', 2).compact

      if port.nil?
        port = host
        ['localhost', port]
      else
        [host, port]
      end
    end

    def connect_tcp_bencode!(host, port, socket_klass: TCPSocket)
      logger.debug(self) { "connect_tcp_bencode #{host.inspect} #{port.inspect}" }
      t = BencodeTransportBuilder.new { socket_klass.new(host, port) }
      Nrepl.new(t)
    end

    def connect_tcp_bencode(*args)
      connect_tcp_bencode!(*args)
    rescue Errno::ECONNREFUSED => ex
      logger.warn(ex.inspect)
      nil
    end

    def try_connect_using_nrepl_port
      return unless File.exist?('.nrepl-port')

      connect_tcp_bencode('localhost', IO.read('.nrepl-port'))
    end

    def silence_warnings
      verbose = $VERBOSE
      $VERBOSE = nil
      yield
    ensure
      $VERBOSE = verbose
    end
  end
end
