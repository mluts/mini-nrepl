require 'socket'

module MiniNrepl
  class TCPSocket
    def initialize(*conn_args)
      @conn_args = conn_args
    end

    def connect
      yield socket
    end

    private

    def socket
      ::TCPSocket.new(*@conn_args)
    end
  end
end
