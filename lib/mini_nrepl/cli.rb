# frozen_string_literal: true

require 'optparse'
require 'mini_nrepl/logging'
require 'mini_nrepl'
require 'mini_nrepl/nrepl/console_handler'
require 'mini_nrepl/util/code_formatter'
require 'mini_nrepl/util/eval'
require 'mini_nrepl/clj'

module MiniNrepl
  # Command-Line interface
  class CLI
    # Wrapper over stdout/stderr
    class Console
      def initialize(io)
        @io = io
      end

      def puts(*args)
        @io.puts(*args)
      end

      def abort(msg)
        abort(msg.to_s)
      end
    end

    def self.run!(argv)
      new(argv).run!
    end

    attr_reader :argv, :opts

    def initialize(argv, console: Console.new($stdout), repl: nil)
      @argv = argv.dup
      @opts = {}
      @log_levels = [Logger::WARN, Logger::INFO, Logger::DEBUG]
      @log_level = 0
      @console = console
      parse_options!
      @console_handler = Nrepl::ConsoleHandler.new(@console)
      @console_handler_proc = @console_handler.to_proc
      @repl = repl # For testing purposes
    end

    def parse_options! # rubocop:disable MethodLength, AbcSize
      @parser = OptionParser.new do |opt|
        opt.separator "Util for calling clojure's nrepl"

        opt.on('-v', 'Verbose') do
          @log_level += 1
          @log_level = [@log_levels.count - 1, @log_level].min
        end

        opt.on('-n', 'Use .nrepl-port file created by "lein repl"') do
          opts[:use_nrepl_port] = true
        end

        opt.on('-a ADDR', 'Nrepl address') do |addr|
          opts[:nrepl_addr] = addr
        end

        opt.on('-e CODE', 'Eval code') do |code|
          opts[:eval] = code
        end

        opt.on('-F FILE_OR_CODE', 'Code to format. Can be "-" to read from stdin') do |f|
          opts[:code_to_format] = f
        end

        opt.on('-C', 'Pry console inside Nrepl instance') do
          opts[:pry] = true
        end

        opt.on('-l CLJ_FILE', 'Eval file') do |f|
          opts[:nrepl_load_file] = f
        end
      end
      @parser.parse!(argv)

      Logging.logger.level = @log_levels.fetch(@log_level)
    end

    # Exit from program with message and help message
    def die!(msg)
      msg = "#{msg}\n" if msg
      @console.abort([msg, @parser].compact.join("\n"))
    end

    def repl
      @repl ||=
        begin
          if (addr = opts[:nrepl_addr])
            host, port = MiniNrepl.parse_addr(addr)
            MiniNrepl.connect_tcp_bencode!(host, port)
          elsif opts[:use_nrepl_port]
            MiniNrepl.try_connect_using_nrepl_port
          end
        end || die!('Specify nrepl addr or use .nrepl-port for connection')
    end

    def format_code(file)
      code =
        if file == '-'
          ARGF.read
        elsif File.exist?(file)
          IO.read(file)
        else
          file
        end

      Util::CodeFormatter.new(repl).format_code(code)
    end

    def run!
      if (code = opts[:eval])
        repl.clone_session
        MiniNrepl::Util::Eval.new(repl).eval!(code, &@console_handler_proc)
      elsif (f = opts[:code_to_format])
        res = format_code(f)
        $stdout.puts(res) if res
      elsif opts[:pry]
        require 'pry'
        repl.pry
      elsif (f = opts[:nrepl_load_file])
        repl.clone_session
        MiniNrepl::Util::Eval.new(repl).eval!(IO.read(f), &@console_handler_proc)
      else
        puts @parser.to_s
      end
    end
  end
end
