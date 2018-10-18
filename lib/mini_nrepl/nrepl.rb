# frozen_string_literal: true

require 'set'

module MiniNrepl
  # Repl operations
  class Nrepl
    Error = Class.new(StandardError)

    # Single operation class

    attr_reader :tt
    def initialize(transport)
      @tt = transport
      @ops = {}
    end

    def inject_ops!
      describe(verbose: true)
    end

    def describe(verbose: true)
      tt.send(op: 'describe', 'verbose?': verbose.to_s)
    end
  end
end
