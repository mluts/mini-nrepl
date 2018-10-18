# frozen_string_literal: true

require 'test_helper'

require 'mini_nrepl'

class MiniNreplTest < Minitest::Test
  def test_parse_addr
    assert_equal %w[localhost 1234], MiniNrepl.parse_addr('1234')
    assert_equal %w[falcon 1234], MiniNrepl.parse_addr('falcon:1234')
  end
end
