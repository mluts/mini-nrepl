# frozen_string_literal: true

require 'test_helper'

require 'mini_nrepl'

class MiniNreplTest < Minitest::Test
  def test_parse_addr
    assert_equal %w[localhost 1234], MiniNrepl.parse_addr('1234')
    assert_equal %w[falcon 1234], MiniNrepl.parse_addr('falcon:1234')
  end

  def test_connect_tcp_bencode
    host = 'localhost'
    port = 1234

    klass = Minitest::Mock.new
    klass.expect(:new, nil) do
      raise Errno::ECONNREFUSED
    end

    assert_nil MiniNrepl.connect_tcp_bencode(host, port, socket_klass: klass)
  end
end
