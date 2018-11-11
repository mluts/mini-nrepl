# frozen_string_literal: true

require 'mini_nrepl/clj'

module MiniNrepl
  # Clojure fn's atop Clj
  module CljLib
    include Clj

    extend self # rubocop:disable ModuleFunction

    # @param path [String] Path to clojure file with ns declaration
    # @return [String] Clojure code to read ns name from given filesystem path
    def read_ns(path) # rubocop:disable MethodLength
      do_(
        require_ns('clojure.tools.namespace.parse'),
        let(
          {
            'read-ns' => fn(['path'],
                            thread_last(
                              '(clojure.java.io/reader path)',
                              '(java.io.PushbackReader.)',
                              '(clojure.tools.namespace.parse/read-ns-decl)'
                            )),

            'extract-ns-name' => fn(['ns-form'],
                                    '(when ns-form (nth ns-form 1))')
          },
          thread_last(
            to_clj(path),
            '(read-ns)',
            '(extract-ns-name)'
          )
        )
      )
    end

    def read_ns_from_code(code)
      do_(
        require_ns('clojure.tools.namespace.parse'),
        let(
          {
            'read-ns' => fn(['code'],
                            thread_last(
                              '(java.io.StringReader. code)',
                              '(clojure.java.io/reader)',
                              '(java.io.PushbackReader.)',
                              '(clojure.tools.namespace.parse/read-ns-decl)'
                            )),

            'extract-ns-name' => fn(['ns-form'],
                                    '(when ns-form (nth ns-form 1))')
          },
          thread_last(
            to_clj(code),
            '(read-ns)',
            '(extract-ns-name)'
          )
        )
      )
    end
  end
end
