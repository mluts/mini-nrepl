require "test_helper"

class Mini::NreplTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Mini::Nrepl::VERSION
  end

  def test_it_does_something_useful
    assert false
  end
end
