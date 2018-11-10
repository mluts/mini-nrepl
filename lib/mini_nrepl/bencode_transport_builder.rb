# frozen_string_literal: true

require 'mini_nrepl/bencode_transport'

module MiniNrepl
  # The class designed to be a wrapper over IO constructor to
  # be able open connection each time when we need to send
  # something through a transport
  #
  # For example keeping the TCP connection open proves to be not reliable, because
  # socket can become closed on other side and i don't know any way to determine if it's closed
  class BencodeTransportBuilder
    def initialize(&io_proc)
      @io_proc = io_proc
    end

    # Builds IO, and delegates to a transport using that IO
    def send(*args, &block)
      build { |tt| tt.public_send(:send, *args, &block).to_a }
    end

    private

    def build
      io = @io_proc.call
      yield ::MiniNrepl::BencodeTransport.new(io)
    ensure
      io&.close
    end
  end
end
