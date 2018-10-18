# frozen_string_literal: true

require 'test_helper'
require 'mini-nrepl/bencode_transport'

module MiniNrepl
  class BencodeTransportTest < Minitest::Test
    def test_stop_reading_when_see_done
      responses = [
        { 'out' => 'foo' },
        { 'status' => %w[done] }
      ]
      io = FakeIO.new(responses.map(&:bencode).join)

      t = BencodeTransport.new(io)
      responses2 = t.send(op: 'eval', code: '123').to_a

      assert_equal responses2, responses
    end

    def test_stop_reading_when_see_error
      responses = [
        { 'out' => 'foo' },
        { 'status' => %w[error] }
      ]
      io = FakeIO.new(responses.map(&:bencode).join)

      t = BencodeTransport.new(io)
      responses2 = t.send(op: 'eval', code: '123').to_a

      assert_equal responses2, responses
    end

    def test_stop_reading_when_see_unknown_op
      responses = [
        { 'status' => %w[unknown-op] }
      ]
      io = FakeIO.new(responses.map(&:bencode).join)

      t = BencodeTransport.new(io)
      responses2 = t.send(op: 'eval', code: '123').to_a

      assert_equal responses2, responses
    end
  end
end
