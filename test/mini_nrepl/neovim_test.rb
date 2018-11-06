# frozen_string_literal: true

require 'test_helper'
require 'mini_nrepl/neovim'

class FakeNrepl < Minitest::Mock
  def expect_op(name, args, ret)
    expect(:op, ret) do |name_, args_, &block|
      ret.each { |v| block.call(v) } if block
      name == name_ && args_ == args
    end
  end
end

module MiniNrepl
  class NeovimPluginTest < Minitest::Test
    attr_reader :repl, :plugin, :nvim

    def setup
      @repl = FakeNrepl.new
      @plugin = NeovimPlugin.new
      @nvim = Minitest::Mock.new
      @plugin.nrepl = @repl
    end

    def teardown
      nvim.verify
      repl.verify
    end

    def out_res(out)
      [{ 'out' => out }]
    end

    def val_res(ns_, val)
      [{ 'ns' => ns_, 'value' => val }]
    end

    def test_nrepl_eval # rubocop:disable AbcSize
      code = '(println 123) (+ 1 2)'

      response = out_res('123') + val_res('foo.bar', nil) + val_res('foo.bar', '3')

      repl.expect_op('eval', { code: code }, response)

      nvim.expect(:out_write, nil, ["123\n"])
      nvim.expect(:out_write, nil, ["foo.bar=>\n"])
      nvim.expect(:out_write, nil, ["foo.bar=>3\n"])

      plugin.nrepl_eval(nvim, code)
    end

    def test_nrepl_format_code
      code = "(\n+\n1 2)"
      code2 = '(+ 1 2)'
      line = code
      lnum = 42
      lcount = 3
      char = ''

      nvim.expect(:call_function, '', ['mode', []])
      nvim.expect(:call_function, line, ['getline', [lnum]])
      nvim.expect(:call_function, [line], ['getline', [lnum, lnum + lcount - 1]])
      nvim.expect(:set_var, nil, ['_nrepl_formatted_code', code2])
      nvim.expect(
        :command,
        nil,
        [NeovimUtil.replace_with_variable_cmd(lnum, lcount, 'g:_nrepl_formatted_code')]
      )

      repl.expect_op('format-code', { code: code }, [{ 'formatted-code' => code2 }])

      res = plugin.nrepl_format_code(nvim, lnum, lcount, char)

      assert_equal 0, res
    end
  end
end
