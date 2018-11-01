# frozen_string_literal: true

require 'test_helper'
require 'mini_nrepl/util/eval'

module MiniNrepl
  module Util
    class EvalTest < Minitest::Test
      def test_out_and_values
        nrepl = Minitest::Mock.new
        response = [
          { 'value' => 'nil' }, { 'value' => '3' }, { 'out' => '2' }
        ]
        code = '(println 2) (+ 1 2)'
        nrepl.expect(:op, response, ['eval', { code: code, id: FakeUuidGenerator.uuid }])

        actual = Eval.new(nrepl).eval(code)
        expected = {
          values: %w[nil 3], out: ['2']
        }
        assert_equal expected, actual
      end

      def test_exception
        nrepl = Minitest::Mock.new
        response = [
          { 'ex' => '1', 'root-ex' => '2' }, { 'out' => '2' }
        ]
        code = '(println 2) (+ 1 2)'
        nrepl.expect(:op, response, ['eval', { code: code, id: FakeUuidGenerator.uuid }])

        actual = Eval.new(nrepl).eval(code)
        expected = {
          ex: [%w[1 2]], out: %w[2]
        }
        assert_equal expected, actual
      end

      def test_eval!
        nrepl = Minitest::Mock.new
        response = [
          { 'ex' => '1', 'root-ex' => '2' }, { 'out' => '2' }
        ]
        code = '(println 2) (+ 1 2)'
        nrepl.expect(:op, response, ['eval', { code: code, id: FakeUuidGenerator.uuid }])

        assert_raises Eval::Error do
          Eval.new(nrepl).eval!(code)
        end
      end

      def test_load_file
        nrepl = Minitest::Mock.new
        response = [
          { 'value' => 'nil' }, { 'value' => '3' }, { 'out' => '2' }
        ]
        file = 'foo.clj'
        code = Clj.load_file(file)
        nrepl.expect(:op, response, ['eval', { code: code,
                                               id: FakeUuidGenerator.uuid }])

        actual = Eval.new(nrepl).load_file(file)
        expected = {
          values: %w[nil 3], out: ['2']
        }
        assert_equal expected, actual
      end
    end
  end
end
