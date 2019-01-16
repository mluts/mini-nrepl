# frozen_string_literal: true

require 'neovim'
require 'mini_nrepl/nrepl/result_handler'
require 'mini_nrepl/neovim_util'
require 'mini_nrepl/util/code_formatter'
require 'mini_nrepl/clj_lib'
require 'mini_nrepl/util/eval'
require 'mini_nrepl/util/symbol'

module MiniNrepl
  # Neovim plugin interface
  class NeovimPlugin
    include Logging

    # Handles neovim output
    class NvimresultHandler < Nrepl::ResultHandler
      include Logging
      attr_reader :nvim

      # Configures ResultHandler to handle certain messages from nrepl
      def initialize
        super

        on('value') do |res|
          ns, val = res.values_at('ns', 'value')
          out_writeln("#{ns}=> #{val}")
        end

        on('out') do |res|
          out_writeln(res['out'])
        end

        on('err') do |res|
          err_writeln(res['err'])
        end
      end

      # Convenience method to add \n to the end of string because nvim will show-up
      # message only with trailing newline
      #
      # @param msg [String] Echo 'msg' to neovim
      def out_writeln(msg)
        nvim.out_writeln(msg)
      end

      def err_writeln(msg)
        nvim.err_write("#{msg}\n")
      end

      # @param nvim [Neovim::Client]
      #   Neovim client. Should always be set when handling nrepl output
      # @return [Proc] Proc to be passed into Nrepl#op method
      def to_proc(nvim)
        p = super()
        proc do |*args|
          logger.debug(self.class) { args.inspect }
          with_nvim(nvim) { p.call(*args) }
        end
      end

      private

      def with_nvim(nvim)
        was = @nvim
        @nvim = nvim
        yield
      ensure
        @nvim = was
      end
    end

    attr_accessor :neovim_host, :nrepl_connector
    attr_writer :nrepl

    # @param nrepl [MiniNrepl::Nrepl] Nrepl to operate on in nvim
    def initialize(neovim_host: ::Neovim, nrepl_connector: ::MiniNrepl)
      @result_handler = NvimresultHandler.new
      @nrepl = nil
      @neovim_host = neovim_host
      @nrepl_connector = nrepl_connector
      MiniNrepl::Logging.redirect_to_file!('/tmp/neovim_mini_nrepl.log')
    end

    def nrepl(nvim = nil)
      @nrepl ||= nrepl_connect(nvim)
    end

    # Initialize neovim plugin
    def init!
      logger.info(self.class) { 'Initializing neovim plugin' }

      neovim_host.plugin do |plug|
        plug.command(:NreplEval, nargs: 1, &method(:nrepl_eval))

        plug.command(:NreplEvalPrompt, nargs: 0, &method(:nrepl_eval_prompt))

        plug.function(:NreplCurrentNS, sync: true, nargs: 0, &method(:nrepl_current_ns))

        plug.function(:NreplFormatCode, sync: true, &method(:nrepl_format_code))

        plug.command(:NreplConnect, nargs: '?', &method(:nrepl_connect))

        plug.command(:NreplReloadNS, nargs: 1, &method(:nrepl_reload_ns))

        plug.command(:NreplReloadCurrentNS, nargs: 0, &method(:nrepl_reload_current_ns))

        plug.command(:NreplJumpToSymbol, sync: true, nargs: '+', &method(:nrepl_jump_to_symbol))

        plug.command(:NreplJumpToCurrentSymbol, sync: true, nargs: 0, &method(:nrepl_jump_to_current_symbol))

        plug.command(:NreplSymbolDoc, sync: true, nargs: '+', &method(:nrepl_symbol_doc))

        plug.command(:NreplCurrentSymbolDoc, sync: true, nargs: 0, &method(:nrepl_current_symbol_doc))

        plug.command(:NreplTestNS, nargs: 1, &method(:nrepl_test_ns))

        plug.command(:NreplTestThisNS, nargs: 0, &method(:nrepl_test_this_ns))
        plug.command(:SNreplTestThisNS, sync: true, nargs: 0, &method(:nrepl_test_this_ns))

        plug.command(:NreplTestThisFn, nargs: 0, &method(:nrepl_test_this_fn))
        plug.command(:SNreplTestThisFn, sync: true, nargs: 0, &method(:nrepl_test_this_fn))

        plug.autocmd(:FileType, pattern: 'clojure') do |nvim|
          nvim.command('nmap <buffer> <Leader>ce :NreplEvalPrompt<CR>')
          nvim.command('nmap <buffer> <nowait> <Leader>r :NreplReloadCurrentNS<CR>')
          nvim.command('nmap <buffer> [<C-d> :NreplJumpToCurrentSymbol<CR>')
          nvim.command('nmap <buffer> ]<C-d> :NreplJumpToCurrentSymbol<CR>')
          nvim.command('nmap <buffer> [d :NreplCurrentSymbolDoc<CR>')
          nvim.command('nmap <buffer> ]d :NreplCurrentSymbolDoc<CR>')
          nvim.command('nmap <buffer> <C-w>[ :split +NreplJumpToCurrentSymbol<CR>')
          nvim.command('nmap <buffer> <C-w><C-[> :split +NreplJumpToCurrentSymbol<CR>')
          nvim.command('nmap <buffer> [t :NreplTestThisNS<CR>')
          nvim.command('nmap <buffer> [T :NreplTestThisFn<CR>')
        end
      end
    end

    def current_fn(nvim)
      line_no = NeovimUtil.cur_line(nvim)
      content = NeovimUtil.read_current_buffer(nvim)

      content.each_line.first(line_no).reverse.lazy.map do |line|
        if (m = /^\s*\(def\S+\s+(?<fn>\S+)/.match(line))
          m['fn']
        end
      end.reject(&:nil?).first
    end

    def nrepl_test_this_fn(nvim)
      fn = current_fn(nvim)
      return unless fn

      ns = nrepl_current_ns(nvim)

      res = nrepl_eval(
        nvim,
        Clj.do_(
          Clj.reload_ns(ns),
          Clj.test_vars("#{ns}/#{fn}")
        ),
        silent: true
      )
      show_in_quickfix(nvim, res)
    end

    def show_in_quickfix(nvim, res)
      out = res.values_at(:out, :values).compact.flatten.join("\n")
      NeovimUtil.quickfix_replace(nvim, out)
    end

    def nrepl_test_this_ns(nvim)
      logger.debug(self.class) { 'nrepl_test_this_ns' }
      ns = nrepl_current_ns(nvim)
      logger.debug(self.class) { "ns: #{ns.inspect}" }
      nrepl_test_ns(nvim, ns)
    end

    def nrepl_test_ns(nvim, ns)
      res = nrepl_eval(nvim, Clj.run_tests(ns), silent: true)
      show_in_quickfix(nvim, res)
    end

    def nrepl_current_symbol_doc(nvim)
      word = nvim.call_function('expand', ['<cword>'])
      ns = nrepl_current_ns(nvim)
      nrepl_symbol_doc(nvim, ns, word)
    end

    def nrepl_symbol_doc(nvim, ns, symbol)
      doc = MiniNrepl::Util::Symbol.new(nrepl(nvim), ns, symbol).doc
      return unless doc

      logger.debug(self.class) { "docstring: #{doc.inspect}" }

      nvim.out_write("#{doc.strip}\n")
    end

    def nrepl_jump_to_current_symbol(nvim)
      word = nvim.call_function('expand', ['<cword>'])
      ns = nrepl_current_ns(nvim)
      nrepl_jump_to_symbol(nvim, ns, word)
    end

    def nrepl_jump_to_symbol(nvim, ns, sym)
      file = MiniNrepl::Util::Symbol.new(nrepl(nvim), ns, sym).nvim_file
      return unless file

      path, line = file.values_at(:path, :line)
      nvim.command("edit #{path}")
      nvim.command("keepjumps norm! #{line}G")
    end

    def nrepl_reload_current_ns(nvim)
      ns = nrepl_current_ns(nvim)
      nrepl_reload_ns(nvim, ns)
    end

    def nrepl_reload_ns(nvim, ns)
      nrepl_eval(nvim, Clj.reload_ns(ns))
    end

    def nrepl_current_ns(nvim)
      logger.debug(self.class) { "called #{__method__}" }

      path = NeovimUtil.current_path(nvim)

      clj_code =
        if File.readable?(path)
          CljLib.read_ns(path)
        else
          logger.debug(self.class) { "#{path} unreadable" }
          code = NeovimUtil.read_current_buffer(nvim)
          CljLib.read_ns_from_code(code)
        end
      res = nrepl_eval(nvim, clj_code, silent: true)
      res.fetch(:values, []).first
    end

    # @param nvim [Neovim::Client] Current neovim client
    # @param code [String] Clojure code
    def nrepl_eval(nvim, code, silent: false)
      logger.debug(self.class) { "nrepl_eval (silent: #{silent}) #{code.inspect}" }

      op = MiniNrepl::Util::Eval.new(nrepl)

      if silent
        op.eval(code)
      else
        op.eval(code, &@result_handler.to_proc(nvim))
      end.tap { |res| logger.debug(self.class) { "nrepl_eval_res #{res.inspect}" } }
    end

    # @param nvim [Neovim::Client] Current neovim client
    def nrepl_eval_prompt(nvim)
      ns = nrepl_current_ns(nvim)
      logger.debug(self.class) { 'nrepl_eval_prompt' }
      code = nvim.call_function('input', ["#{ns}=> "])
      logger.debug(self.class) { "nrepl_eval_prompt code #{code.inspect}" }
      nrepl_eval(nvim, Clj.in_ns(ns, code))
    end

    def nrepl_format_code(nvim, lnum, lcount, _char)
      mode = nvim.call_function('mode', [])
      line = nvim.call_function('getline', [lnum])

      return -1 if /[iR]/.match(mode) || line =~ /^\s+;/

      code = nvim.call_function('getline', [lnum, lnum + lcount - 1]).join("\n")

      formatted_code = MiniNrepl::Util::CodeFormatter.new(nrepl).format_code(code)

      if formatted_code
        out = formatted_code.each_line.to_a.map(&:rstrip).join("\n")
        nvim.set_var('_nrepl_formatted_code', out)
        nvim.command(NeovimUtil.replace_with_variable_cmd(lnum, lcount, 'g:_nrepl_formatted_code'))
        0
      else
        -1
      end
    end

    def nrepl_connect(nvim, addr = nil)
      self.nrepl =
        if addr
          host, port = MiniNrepl.parse_addr(addr)
          nrepl_connector.connect_tcp_bencode(host, port) ||
            error!(nvim, "#{host}:#{port} not available")
        else
          nrepl_connector.try_connect_using_nrepl_port ||
            error!(nvim, ".nrepl-port not found\n")
        end
    end

    private

    def error!(nvim, msg)
      if nvim
        nvim.err_write("#{msg}\n")
      else
        raise msg.to_s
      end
    end
  end
end
