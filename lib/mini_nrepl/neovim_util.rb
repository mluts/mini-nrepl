# frozen_string_literal: true

module MiniNrepl
  module NeovimUtil
    module_function

    def replace_with_variable_cmd(lnum, lcount, var)
      "normal! #{lnum}ggV#{lcount - 1}j\"=#{var}\np"
    end
  end
end
