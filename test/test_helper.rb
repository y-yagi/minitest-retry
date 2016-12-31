$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pry'
require 'minitest/retry'
require 'minitest/autorun'

module RetryTest
  attr_accessor :reporter

  def setup
    self.reporter = Minitest::CompositeReporter.new
    self.reporter << Minitest::SummaryReporter.new
  end

  protected

  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    out.string
  ensure
    $stdout = STDOUT
  end

  def declare_test_case(&block)
    executed = false
    output = capture_stdout do
      retry_test = Class.new(Minitest::Test, &block)
      Minitest::Runnable.run_one_method(retry_test, :test, reporter)
    end
    { executed: executed, output: output }
  end

  def execute_test(options = {}, &block)
    executed = false
    output = capture_stdout do
      retry_test =
        Class.new(Minitest::Test) do
          @@block = block
          Minitest::Retry.use!(options)
          Minitest::Retry.on_failure do
            executed = true
          end

          def test
            @@block.call
          end
        end
      Minitest::Runnable.run_one_method(retry_test, :test, reporter)
    end
    { executed: executed, output: output }
  end

  class TestError < StandardError; end
end

MiniTest::Test.include RetryTest
