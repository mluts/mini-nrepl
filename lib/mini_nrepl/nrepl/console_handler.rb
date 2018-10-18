# frozen_string_literal: true

require 'mini_nrepl/nrepl/result_handler'

module MiniNrepl
  class Nrepl
    # Makes real-time nrepl output in console
    class ConsoleHandler < ResultHandler
      def initialize(console) # rubocop:disable AbcSize, MethodLength
        super

        on('status', 'interrupted') do
          console.puts 'Nrepl Interrupted'
        end

        on('status', 'eval-error') do
          console.puts 'Evaluation error'
        end

        on('ex') do |res|
          console.puts res.values_at('ex', 'root-ex').compact
        end

        on('err') do |res|
          console.puts res['err']
        end

        on('out') do |res|
          console.puts res['out']
        end

        on('value') do |res|
          ns, value = res.values_at('ns', 'value')
          console.puts("#{ns}=> #{value}")
        end
      end
    end
  end
end
