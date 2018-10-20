# frozen_string_literal: true

require 'set'
require 'mini_nrepl/logging'

module MiniNrepl
  class Nrepl
    # Represends single nrepl operation
    class Op
      include Logging
      Erorr = Class.new(StandardError)

      attr_reader :name, :desc

      # @param name [String] Operation name as was in "describe" response
      # @param description [Hash]
      #    Operation description as was in "describe" response
      #    Should contain "doc", "optional", "requires" keys
      def initialize(name, description)
        # logger.debug(self.class) { "Initializing op with #{name.inspect} #{description.inspect}" }
        @name = name.to_s
        @desc = description.to_h
      end

      # @return [String] human-readable op description
      def doc
        desc.fetch('doc')
      end

      # Performs given operation on transport
      # @param transport [#send(Hash)] A transport object
      # @param args [Hash] Op args
      # @return [Enumerator] Whatever transport returns
      def call(transport, args, &block)
        logger.debug(self.class) { "call #{transport.inspect} -> #{name} #{args.inspect}" }

        check_args!(args)

        transport.send(args.merge(op: name).reject { |_k, v| v.nil? }, &block)
      end

      # @return [Hash] Args documentation
      def args
        @args ||= desc.fetch('optional').merge(desc.fetch('requires')).transform_keys(&:to_sym)
      end

      private

      def allowed_keys
        @allowed_keys ||= Set.new(args.keys + [:session])
      end

      def check_args!(args)
        keys = Set.new(args.keys)
        unsupported = keys - allowed_keys
        raise Error, "Unsupported args: #{unsupported.to_a.join(', ')}" if unsupported.any?
      end
    end
  end
end
