# frozen_string_literal: true

require 'optparse'
require 'mini_nrepl/logging'
require 'mini_nrepl'
require 'mini_nrepl/nrepl/console_handler'
require 'mini_nrepl/util/code_formatter'

module MiniNrepl
  # Command-Line interface
  class CLI
    class Console
      def initialize(io)
        @io = io
      end

      def puts(*args)
        @io.puts(*args)
      end
    end

    def self.run!(argv)
      new(argv).run!
    end

    attr_reader :argv, :opts

    def initialize(argv)
      @argv = argv.dup
      @opts = {}
      @log_levels = [Logger::WARN, Logger::INFO, Logger::DEBUG]
      @log_level = 0
      @console = Console.new($stdout)
      parse_options!
      @console_handler = Nrepl::ConsoleHandler.new(@console)
      @console_handler_proc = @console_handler.to_proc
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

        opt.on('-C', 'Pry console inside Nrepl instalce') do
          opts[:pry] = true
        end
      end
      @parser.parse!(argv)

      Logging.logger.level = @log_levels.fetch(@log_level)
    end

    # Exit from program with message and help message
    def die!(msg)
      msg = "#{msg}\n" if msg
      abort([msg, @parser].compact.join("\n"))
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
      if (code = opts[:code])
        repl.op('eval', code: code, &@console_handler_proc).to_a
      elsif (f = opts[:code_to_format])
        res = format_code(f)
        $stdout.puts(res) if res
      elsif opts[:pry]
        require 'pry'
        repl.pry
      end
    end
  end
end
