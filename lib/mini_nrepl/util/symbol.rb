# frozen_string_literal: true

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
      end

      def doc
        get_info
        return unless @info.any?

        @info.fetch(:docstring)
      rescue => ex
        logger.error(self.class) do
          ['in doc method', "@info: #{@info.inspect}", ex.inspect].join("\n")
        end
        raise
      end

      def nvim_file
        get_info
        return unless @info[:file]

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
            file: get_file(res),
            docstring: get_docstring(res)
          )
        end
      end

      def get_docstring(res)
        ns = res.fetch('ns', nil)
        name = res.fetch('name', nil)
        args = res.fetch('arglists-str', nil)
        doc = Array(res.fetch('doc', '')).join("\n") 
        # Workaround fo\ :doc key
        # It returns empty vector ([]) for protocols
        full_name = [ns, name].compact.join("/")

        [
          full_name,
          args,
          ' ',
          doc.each_line.map(&:strip)
        ].compact.join("\n")
      end

      def get_file(res)
        return unless res.key?('file')

        file = res.fetch('file', nil)
        line = res.fetch('line', 1)

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
