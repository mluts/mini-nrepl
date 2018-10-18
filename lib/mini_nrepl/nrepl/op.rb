# frozen_string_literal: true

require 'set'

module MiniNrepl
  class Nrepl
    # Represends single nrepl operation
    class Op
      Erorr = Class.new(Nrepl::Error)

      attr_reader :name, :desc

      def initialize(name, description)
        @name = name.to_s
        @desc = description.to_h
      end

      def doc
        desc.fetch('doc')
      end

      def args
        @args ||= desc.fetch('optional').merge(desc.fetch('requires')).transform_keys(&:to_sym)
      end

      def allowed_keys
        @allowed_keys ||= Set.new(args.keys)
      end

      def call(transport, args, &block)
        args.delete(:op)
        keys = Set.new(args.keys)
        unsupported = allowed_keys - keys
        raise Error, "Unsupported args: #{unsupported.to_a.join(', ')}" if unsupported.any?

        transport.send(args.merge(op: name), &block)
      end
    end
  end
end
