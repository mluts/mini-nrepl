# frozen_string_literal: true

require 'neovim'
require 'mini_nrepl/nrepl/result_handler'

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
          out_writeln("#{ns}=>#{val}")
        end

        on('out') do |res|
          out_writeln(res['out'])
        end
      end

      # Convenience method to add \n to the end of string because nvim will show-up
      # message only with trailing newline
      #
      # @param msg [String] Echo 'msg' to neovim
      def out_writeln(msg)
        nvim.out_write("#{msg}\n")
      end

      # @param nvim [Neovim::Client]
      #   Neovim client. Should always be set when handling nrepl output
      # @return [Proc] Proc to be passed into Nrepl#op method
      def to_proc(nvim)
        p = super()
        proc { |*args| with_nvim(nvim) { p.call(*args) } }
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

    attr_reader :nrepl

    # @param nrepl [MiniNrepl::Nrepl] Nrepl to operate on in nvim
    def initialize(nrepl)
      @nrepl = nrepl
      @result_handler = NvimresultHandler.new
    end

    # Initialize neovim plugin
    def init!
      logger.info(self.class) { 'Initializing neovim plugin' }

      ::Neovim.plugin do |plug|
        plug.command(:NreplEval, nargs: 1, &method(:nrepl_eval))

        plug.command(:NreplEvalPrompt, nargs: 0, &method(:nrepl_eval_prompt))

        plug.function(:current_ns, nargs: 0, &method(:nrepl_current_ns))

        plug.autocmd(:FileType, pattern: 'clojure') do |nvim|
          cedit = nvim.get_option('cedit')
          nvim.command("nmap <Leader>ce :NreplEvalPrompt<CR>#{cedit}")
        end

        plug.function(:NreplFormatCode, sync: true, &method(:nrepl_format_code))
      end
    end

    # @param nvim [Neovim::Client] Current neovim client
    # @param code [String] Clojure code
    def nrepl_eval(nvim, code)
      logger.debug(self.class) { "nrepl_eval #{code.inspect}" }
      nrepl.op('eval', code: code, &@result_handler.to_proc(nvim))
    end

    # @param nvim [Neovim::Client] Current neovim client
    def nrepl_eval_prompt(nvim)
      logger.debug(self.class) { 'nrepl_eval_prompt' }
      code = nvim.call_function('input', ['=> '])
      logger.debug(self.class) { "nrepl_eval_prompt code #{code.inspect}" }
      nrepl_eval(nvim, code)
    end

    def nrepl_current_ns(nvim)
    end
  end
end
