# frozen_string_literal: true

require_relative '../test_helper'

Minitest::Retry.use!

class ParallelRetrySampleTest < Minitest::Test
  parallelize_me!

  @@attempts = 0

  def test_flaky
    @@attempts += 1
    assert_equal 2, @@attempts
  end
end
