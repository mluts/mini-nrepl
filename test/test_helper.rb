# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'mini-nrepl'

require 'minitest/autorun'

require 'stringio'

class FakeIO < StringIO
  attr_writer :in

  def initialize(*args)
    super
    @in = StringIO.new
  end

  def write(*args)
    @in.write(*args)
  end
end
