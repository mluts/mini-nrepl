# frozen_string_literal: true

require 'test_helper'
require 'mini_nrepl/nrepl/op'

module MiniNrepl
  class Nrepl
    class OpTest < Minitest::Test
      def eval_op
        [
          'eval',
          {
            'requires' => {
              'code' => 'code to eval'
            },
            'optional' => {},
            'doc' => 'Evaluates code'
          }
        ]
      end

      def test_interprets_description_correctly
        tt = FakeTransport.new

        name, desc = eval_op

        op = Op.new(name, desc)

        op.call(tt, code: '123').to_a

        assert_equal tt.msgs, [{ op: name, code: '123' }]
      end
    end
  end
end
