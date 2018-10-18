# frozen_string_literal: true

require 'mini_nrepl/version'
require 'socket'
require 'mini_nrepl/bencode_transport'
require 'mini_nrepl/nrepl'
require 'mini_nrepl/logging'

# Base module for gem
module MiniNrepl
  Error = Class.new(StandardError)
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

    def connect_tcp_bencode!(host, port)
      logger.debug(self) { "connect_tcp_bencode #{host.inspect} #{port.inspect}" }
      s = TCPSocket.new(host, port)
      t = BencodeTransport.new(s)
      Nrepl.new(t)
    end

    def try_connect_using_nrepl_port
      return unless File.exist?('.nrepl-port')

      connect_tcp_bencode!('localhost', IO.read('.nrepl-port'))
    end
  end
end
