# frozen_string_literal: true

require 'mini_nrepl/version'
require 'socket'
require 'mini_nrepl/bencode_transport'
require 'mini_nrepl/nrepl'

# Base module for gem
module MiniNrepl
  class << self
    def connect_tcp_bencode!(host, port)
      s = TCPSocket.new(host, port)
      t = BencodeTransport.new(s)
      Nrepl.new(t)
    end
  end
end
