# frozen_string_literal: true

require 'optparse'
require 'mini_nrepl/logging'
require 'mini_nrepl'
require 'mini_nrepl/nrepl/console_handler'

module MiniNrepl
  # Command-Line interface
  class CLI
    def self.run!(argv)
      new(argv).run!
    end

    attr_reader :argv, :opts

    def initialize(argv)
      @argv = argv.dup
      @opts = {}
      @log_levels = [Logger::WARN, Logger::INFO, Logger::DEBUG]
      @log_level = 0
      parse_options!
      @console_handler = Nrepl::ConsoleHandler.new($stdout)
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

        opt.on('-s NREPL_SESSION_FILE', 'Preserve session in file') do |path|
          opts[:nrepl_session_file] = path
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

    def run!
      opts.each do |opt, val|
        case opt
        when :eval
          code = val.to_s
          repl.op('eval', code: code, &@console_handler_proc).to_a.inspect
        end
      end
    end
  end
end
