require 'test_helper'

class Minitest::RetryTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Minitest::Retry::VERSION
  end

  def test_fail
    assert nil, 'fail test'
  end
end
