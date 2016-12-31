require 'test_helper'

class Minitest::OnFailureTest < Minitest::Test
  def test_run_failure_callback_on_failure
    on_failure_block_has_ran = execute_test { assert false, 'fail test' }[:executed]
    assert on_failure_block_has_ran
  end

  def test_do_not_run_failure_callback_on_success
    on_failure_block_has_ran = execute_test { assert true }[:executed]
    refute on_failure_block_has_ran
  end

  def test_do_not_run_failure_callback_on_skip
    on_failure_block_has_ran = execute_test { skip }[:executed]
    refute on_failure_block_has_ran
  end
end
