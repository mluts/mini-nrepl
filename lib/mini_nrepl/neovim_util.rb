# frozen_string_literal: true

require 'mini_nrepl/logging'

module MiniNrepl
  module NeovimUtil
    module_function

    def replace_with_variable_cmd(lnum, lcount, var)
      "normal! #{lnum}ggV#{lcount - 1}j\"=#{var}\np"
    end

    def current_path(nvim)
      nvim.call_function('expand', %w[%])
    end

    def cur_line(nvim)
      _buf, line, = nvim.call_function('getcurpos', [])
      line
    end

    def get_lines(nvim, line1, line2)
      nvim.call_function('getline', [line1, line2])
    end

    def read_current_buffer(nvim)
      nvim.call_function('getline', [1, '$']).join("\n")
    end

    def quickfix_replace(nvim, text)
      return if text == 'nil' || text.to_s.strip.empty?

      Logging.logger.debug(self.class) { "quickfix_replace: #{text.inspect}" }
      items = text.each_line.map { |l| { text: l } }
      nvim.call_function('setqflist', [items, 'r'])
      nvim.command('botright copen')
      nvim.command('norm! ^W^P')
    end
  end
end
