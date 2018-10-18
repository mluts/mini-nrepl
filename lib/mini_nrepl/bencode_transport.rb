# frozen_string_literal: true

require 'bencode'
require 'mini_nrepl/logging'

module MiniNrepl
  # Encodes/Decodes messages to/from BEncode and handles IO
  class BencodeTransport
    Error = Class.new(StandardError)

    include Logging

    # @param io [IO] A Suclass of IO. Can be a TCPSocket for example
    def initialize(io)
      @io = io
      @parser = BEncode::Parser.new(io)
    end

    # Sends encoded message through IO and collects all responses until end of messages
    #
    # @param cmd [Hash] Message hash to be converted into clojure's map
    # @return [Enumerator]
    # @yield [msg] Yields decoded messages if block was provided
    def send(cmd, &block)
      cmd = cmd.to_h
      logger.debug(self.class) { "CMD: #{cmd}" }

      str = cmd.bencode
      logger.debug(self.class) { "Encoded CMD: #{str}" }

      @io.write(cmd.bencode)

      collect_responses(&block)
    end

    private

    # Attempts to read responses until done/error/unknown-op
    def collect_responses
      return to_enum(:collect_responses) unless block_given?

      loop do
        raise Error, 'EOF' if @parser.eos?

        response = @parser.parse!
        logger.debug(self.class) { "Response #{response.inspect}" }
        yield response
        break if end_of_responses?(response)
      end
    end

    # @see https://github.com/clojure/tools.nrepl#handlers
    def end_of_responses?(response)
      done?(response) || error?(response) || unknown_op?(response)
    end

    def done?(response)
      status?(response) && response['status'].include?('done')
    end

    def error?(response)
      status?(response) && response['status'].include?('error')
    end

    def unknown_op?(response)
      status?(response) && response['status'].include?('unknown-op')
    end

    def status?(response)
      response.to_h.key?('status')
    end
  end
end
