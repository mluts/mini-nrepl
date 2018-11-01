# frozen_string_literal: true

require 'test_helper'
require 'mini_nrepl/cli'
require 'tempfile'

module MiniNrepl
  class CliTest < Minitest::Test
    def test_eval
      repl = Minitest::Mock.new
      console = Minitest::Mock.new

      code = '(+ 1 2)'

      repl.expect(:op, [], ['eval', { code: code, id: FakeUuidGenerator.uuid }])

      CLI.new(['-e', code], console: console, repl: repl).run!
    end

    def test_load_file
      repl = Minitest::Mock.new
      console = Minitest::Mock.new

      file = Tempfile.new(['mini-nrepl-test', '.clj'])
      code = '(+ 1 2)'
      file.write(code)
      file.close

      repl.expect(:op, [], ['eval', { code: code,
                                      id: FakeUuidGenerator.uuid }])

      CLI.new(['-l', file.path], console: console, repl: repl).run!
    end
  end
end
