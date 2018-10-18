# frozen_string_literal: true

require 'set'
require 'mini_nrepl/logging'

module MiniNrepl
  class Nrepl
    # Allows to setup flexible handling of nrepl output
    class ResultHandler
      include Logging

      def initialize(*args)
        logger.debug(self.class) { "Initializing with #{args.inspect}" }
        @on = {}
      end

      def to_proc
        proc { |msg| handle_message(msg) }
      end

      def on(key, val = nil, &block)
        return unless block

        val = val ? Set.new(Array(val)) : val

        callbacks = @on.fetch(key, [])
        callbacks << [val, block]

        @on[key] = callbacks
      end

      def handle_message(msg)
        msg.each do |key, val|
          msg_val_set = Set.new(Array(val))

          @on.fetch(key, []).each do |(handle_val_set, block)|
            block.call(msg) if !handle_val_set || (msg_val_set & handle_val_set).any?
          end
        end
      end

      def with_opts(opts)
        was = current_opts
        Thead.current[opts_key] = opts
        yield
      ensure
        Thread.current[opts_key] = was
      end

      def current_opts
        Thread.current[opts_key] || {}
      end

      private

      def opts_key
        @opts_key ||= "ResultHandler->#{self.class}_opts"
      end
    end
  end
end
