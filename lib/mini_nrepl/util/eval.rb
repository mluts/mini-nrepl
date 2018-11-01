# frozen_string_literal: true

require 'securerandom'
require 'mini_nrepl/clj'

module MiniNrepl
  module Util
    # 'eval' op wrapper
    class Eval
      Error = Class.new(StandardError)

      class << self
        attr_accessor :uuid_generator
      end

      self.uuid_generator = SecureRandom

      def initialize(nrepl)
        @nrepl = nrepl
      end

      def eval(code, args: {}, &block)
        id = self.class.uuid_generator.uuid
        fold_results(@nrepl.op('eval', args.merge(code: code, id: id), &block))
      rescue Interrupt
        @nrepl.op('interrupt', 'interrupt-id': id).to_a
        { 'interrupted' => true }
      end

      def eval!(code, &block)
        res = self.eval(code, &block) # rubocop:disable RedundantSelf

        if (ex = res[:ex].to_a).any?
          msg = ex.map { |(ex_, root_ex)| "Ex: #{ex_}. Root-Ex: #{root_ex}" }.join("\n")
          raise Error, "Nrepl raised #{msg}"
        else
          res
        end
      end

      def load_file(path, &block)
        self.eval(MiniNrepl::Clj.load_file(path), &block)
      end

      def load_file!(path, &block)
        self.eval!(MiniNrepl::Clj.load_file(path), &block)
      end

      private

      def fold_results(results)
        results.each_with_object({}) do |res, acc|
          if (out = res['out'])
            (acc[:out] ||= []) << out
          elsif res['ex']
            (acc[:ex] ||= []) << res.values_at('ex', 'root-ex')
          elsif (val = res['value'])
            (acc[:values] ||= []) << val
          end
        end
      end
    end
  end
end
