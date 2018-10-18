# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'mini_nrepl'

require 'minitest/autorun'

require 'stringio'

# Just like an StringIO, but writes into separate io
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

# Class designed to simply collect messages
class FakeTransport
  attr_reader :msgs

  def initialize
    @msgs = []
  end

  def send(msg)
    msgs << msg
  end
end
