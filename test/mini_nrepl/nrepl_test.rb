# frozen_string_literal: true

require 'test_helper'
require 'mini_nrepl/nrepl'

module MiniNrepl
  class NreplTest < Minitest::Test
    def op_hash(name, optional, required = {})
      {
        name => {
          'optional' => optional,
          'requires' => required,
          'doc' => "#{name} doc"
        }
      }
    end

    def sample_ops
      {
        'ops' => [
          op_hash('describe', {}),
          op_hash('eval', {}, 'code' => 'code to eval'),
          op_hash('clone', {'session' => 'session-id'})
        ].reduce({}, :merge)
      }
    end

    def test_initialize_injects_available_ops
      t = Minitest::Mock.new
      t.expect(:send, [sample_ops], [{ op: 'describe', 'verbose?': 'true' }])
      t.expect(:send, [{ 'out' => '123' }], [{ op: 'eval', code: '(+ 120 3)' }])
      r = Nrepl.new(t, store_session: false)
      assert_equal %w[describe eval clone].sort, r.ops.keys.sort

      r.op('eval', code: '(+ 120 3)')
      t.verify
    end
  end
end
