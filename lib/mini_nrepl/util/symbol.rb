require 'mini_nrepl/logging'

module MiniNrepl
  module Util
    class Symbol
      include Logging

      attr_reader :nrepl, :ns, :symbol

      def initialize(nrepl, ns, symbol)
        @nrepl = nrepl
        @ns = ns
        @symbol = symbol
        @info = {}
        get_info
      end

      def nvim_file
        return unless @info.any?

        file = @info.fetch(:file)

        path, in_jar_path, line = file.values_at(:path, :in_jar_path, :line)

        if file[:jar]
          {
            path: "zipfile:#{path}::#{in_jar_path}",
            line: line
          }
        else
          {
            path: path,
            line: line
          }
        end
      end

      private

      def get_info
        return if @info.any?

        res = nrepl.op('info', ns: ns, symbol: symbol).reduce({}, :merge)

        unless res['status'].include?('no-info')
          @info.merge!(
            file: get_file(res)
          )
        end
      end

      def get_file(res)
        file = res.fetch('file')
        line = res.fetch('line')

        logger.debug(self.class) { [file, line].join(':') }

        case file
        when /^file:/
          path = file.split(':', 2)[1]
          {
            path: path,
            jar: false,
            line: line
          }
        when /^jar:file:/
          path_ = file.split(':', 3)[2]
          jar_path, in_jar_path = path_.split('!')
          {
            path: jar_path,
            in_jar_path: in_jar_path.sub(%r{^\/}, ''),
            jar: true,
            line: line
          }
        end
      end
    end
  end
end
