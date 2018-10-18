# frozen_string_literal: true

require 'logger'

module MiniNrepl
  # Logging facility
  module Logging
    class << self
      attr_writer :logger

      def logger
        @logger ||=
          begin
            ::Logger.new($stderr).tap do |l|
              l.level = Logger::DEBUG
            end
          end
      end
    end

    def logger
      Logging.logger
    end
  end
end
