# frozen_string_literal: true

require 'test_helper'
require 'mini_nrepl/neovim'
require 'tempfile'

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
    attr_reader :nrepl, :plugin, :nvim, :host, :plug, :nrepl_connector

    def setup
      @nrepl_connector = Minitest::Mock.new
      @host = Minitest::Mock.new
      @plug = Minitest::Mock.new
      @nrepl = FakeNrepl.new
      @plugin = NeovimPlugin.new(neovim_host: host, nrepl_connector: nrepl_connector)
      @nvim = Minitest::Mock.new
      @plugin.nrepl = @nrepl
    end

    def teardown
      nvim.verify
      nrepl.verify
      plug.verify
      host.verify
      nrepl_connector.verify
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

      nrepl.expect_op('eval', { code: code, id: FakeUuidGenerator.uuid }, response)

      nvim.expect(:out_writeln, nil, ['123'])
      nvim.expect(:out_writeln, nil, ['foo.bar=> '])
      nvim.expect(:out_writeln, nil, ['foo.bar=> 3'])

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

      nrepl.expect_op('format-code', { code: code }, [{ 'formatted-code' => code2 }])

      res = plugin.nrepl_format_code(nvim, lnum, lcount, char)

      assert_equal 0, res
    end

    def test_init
      plug.expect(:command, nil, [:NreplEval, { nargs: 1 }])
      plug.expect(:command, nil, [:NreplEvalPrompt, { nargs: 0 }])
      plug.expect(:function, nil, [:NreplCurrentNS, { nargs: 0, sync: true }])
      plug.expect(:autocmd, nil, [:FileType, { pattern: 'clojure' }])
      plug.expect(:function, nil, [:NreplFormatCode, { sync: true }])
      plug.expect(:command, nil, [:NreplConnect, { nargs: '?' }])
      plug.expect(:command, nil, [:NreplReloadNS, { nargs: 1 }])
      plug.expect(:command, nil, [:NreplReloadCurrentNS, { nargs: 0 }])
      plug.expect(:command, nil, [:NreplJumpToSymbol, { sync: true, nargs: '+' }])
      plug.expect(:command, nil, [:NreplJumpToCurrentSymbol, { sync: true, nargs: 0 }])
      plug.expect(:command, nil, [:NreplSymbolDoc, { sync: true, nargs: '+' }])
      plug.expect(:command, nil, [:NreplCurrentSymbolDoc, { sync: true, nargs: 0 }])
      plug.expect(:command, nil, [:NreplTestNS, { nargs: 1 }])
      plug.expect(:command, nil, [:NreplTestThisNS, { nargs: 0 }])
      plug.expect(:command, nil, [:SNreplTestThisNS, { sync: true, nargs: 0 }])
      plug.expect(:command, nil, [:NreplTestThisFn, { nargs: 0 }])
      plug.expect(:command, nil, [:SNreplTestThisFn, { sync: true, nargs: 0 }])

      host.expect(:plugin, nil) do |&block|
        block.call(plug)
        true
      end

      plugin.init!
    end

    def test_current_ns
      file = Tempfile.new(['mini_nrepl', '.clj'])
      path = file.path
      ns = 'foo.bar'
      code = MiniNrepl::CljLib.read_ns(path)

      nvim.expect(:call_function, path, ['expand', %w[%]])
      nrepl.expect(:op, [{ 'value' => ns }], ['eval', { code: code, id: FakeUuidGenerator.uuid }])

      assert_equal ns, plugin.nrepl_current_ns(nvim)
    ensure
      file&.delete
    end

    def test_nrepl_connect
      nrepl = Object.new
      nrepl_connector.expect(:try_connect_using_nrepl_port, nrepl, [])
      plugin.nrepl_connect(nvim)
      assert_equal nrepl, plugin.nrepl
    end

    def test_nrepl_reload_ns
      ns = 'foo.bar'
      code = MiniNrepl::Clj.reload_ns(ns)
      nrepl.expect(
        :op,
        [{ 'value' => 'nil' }],
        ['eval', { code: code, id: FakeUuidGenerator.uuid }]
      )
      nvim.expect(:out_writeln, nil, ['=> nil'])
      plugin.nrepl_reload_ns(nvim, ns)
    end
  end
end
