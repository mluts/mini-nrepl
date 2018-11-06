# frozen_string_literal: true

require 'mini_nrepl/nrepl/result_handler'

module MiniNrepl
  module Util
    # Allows to format code using cider-nrepl 'format-code' op
    class CodeFormatter
      def initialize(nrepl)
        @nrepl = nrepl
      end

      def format_code(code)
        op_name = 'format-code'
        res_key = 'formatted-code'

        @nrepl.op(op_name, code: code).detect { |r| r[res_key] }&.fetch(res_key)
      end
    end
  end
end
