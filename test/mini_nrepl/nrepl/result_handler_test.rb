# frozen_string_literal: true

require 'minitest'
require 'mini_nrepl/nrepl/result_handler'

module MiniNrepl
  class Nrepl
    class ResultHandlerTest < Minitest::Test
      def sample_msgs
        [
          { 'status' => 'done', 'msg1' => 'val2' },
          { 'status' => 'done', 'msg1' => 'val1' },
          { 'msg2' => 'a' },
          { 'msg2' => 'b' },
          { 'msg2' => 'c' }
        ]
      end

      def test_behaviour
        actual = []

        rh = ResultHandler.new

        rh.on('status') { |res| actual << res.fetch('status') }
        rh.on('msg1', 'val1') { |res| actual << res.fetch('msg1') }
        rh.on('msg2', %w[a b]) { |res| actual << res['msg2'] }

        sample_msgs.each { |msg| rh.to_proc.call(msg) }

        assert_equal %w[done done val1 a b], actual
      end
    end
  end
end
