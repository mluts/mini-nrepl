# frozen_string_literal: true

MiniNrepl.silence_warnings do
  require 'edn'
end

module MiniNrepl
  # Clojure DSL
  module Clj
    module_function

    def symbol(id)
      "'#{id}"
    end

    def var(id)
      "#'#{id}"
    end

    def test_vars(*vars)
      vars = vars.map { |v| var(v) }.join(' ')
      "(clojure.test/test-vars [#{vars}])"
    end

    def require_ns(ns)
      "(require #{symbol(ns)})"
    end

    def reload_ns(ns)
      "(require '[#{ns} :reload true])"
    end

    def run_tests(*nss)
      "(clojure.test/run-tests #{nss.map(&method(:symbol)).join(' ')})"
    end

    def thread_last(*forms)
      "(->> #{forms.join(' ')})"
    end

    def in_ns(ns)
      do_(
        reload_ns(ns),
        "(in-ns #{symbol(ns)})"
      )
    end

    def load_code(code)
      "(load-string #{code.to_edn})"
    end

    def do_(*forms)
      "(do #{forms.join("\n")})"
    end

    def let(hash, form)
      bindings = hash.map do |k, v|
        [k, v].join(' ')
      end.join("\n")
      "(let [#{bindings}]\n#{form})"
    end

    def fn(args, form)
      "(fn [#{args.join(' ')}] #{form})"
    end

    def to_clj(form)
      form.to_edn
    end

    def load_file(path)
      "(load-file #{path.to_edn})"
    end
  end
end
