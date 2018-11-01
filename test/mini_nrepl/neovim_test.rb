# frozen_string_literal: true

require 'test_helper'
require 'mini_nrepl/neovim'

class FakeNrepl < Minitest::Mock
  def expect_op(name, args, ret)
    expect(:op, ret) do |name_, args_, &block|
      ret.each { |v| block.call(v) }
      name == name_ && args_ == args
    end
  end
end

module MiniNrepl
  class NeovimPluginTest < Minitest::Test
    attr_reader :repl, :plugin, :nvim

    def setup
      @repl = FakeNrepl.new
      @plugin = NeovimPlugin.new(repl)
      @nvim = Minitest::Mock.new
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
  end
end
