require 'test_helper'

class Minitest::OnFailureTest < Minitest::Test
  def test_run_failure_callback_on_failure
    on_failure_block_has_ran =
      execute_test do
        assert false, 'fail test'
      end
    assert on_failure_block_has_ran
  end

  def test_do_not_run_failure_callback_on_success
    on_failure_block_has_ran =
      execute_test do
        assert true
      end
    refute on_failure_block_has_ran
  end

  def test_do_not_run_failure_callback_on_skip
    on_failure_block_has_ran =
      execute_test do
        skip
      end
    refute on_failure_block_has_ran
  end

  protected

  def execute_test(&block)
    on_failure_block_has_ran = false
    capture_stdout do
      retry_test =
        Class.new(Minitest::Test) do
          @@block = block
          Minitest::Retry.use!
          Minitest::Retry.on_failure do
            on_failure_block_has_ran = true
          end

          def unique_test
            @@block.call
          end
        end
      Minitest::Runnable.run_one_method(retry_test, :unique_test, reporter)
    end
    on_failure_block_has_ran
  end
end
