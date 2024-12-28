require 'test_helper'

class Minitest::RetryTest < Minitest::Test
  attr_accessor :reporter

  def setup
    self.reporter = Minitest::CompositeReporter.new
    self.reporter << Minitest::SummaryReporter.new
  end

  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    out.string
  ensure
    $stdout = STDOUT
  end

  def test_display_retry_msg
    output = capture_stdout do
      retry_test = Class.new(Minitest::Test) do
        Minitest::Retry.use!
        def fail
          assert false, 'fail test'
        end
      end
      Minitest::Runnable.run_one_method(retry_test, :fail, self.reporter)
    end
    expect = <<-EOS
[MinitestRetry] retry 'fail' count: 1,  msg: fail test
[MinitestRetry] retry 'fail' count: 2,  msg: fail test
[MinitestRetry] retry 'fail' count: 3,  msg: fail test
    EOS

    refute reporter.passed?
    assert_equal expect, output
  end

  def test_display_retry_msg_for_unexpected_exception
    output = capture_stdout do
      retry_test = Class.new(Minitest::Test) do
        Minitest::Retry.use!
        def fail
          raise 'parsing error'
        end
      end
      Minitest::Runnable.run_one_method(retry_test, :fail, self.reporter)
    end

    failed_method_name = RUBY_VERSION >= "3.4" ? "'fail'" : "`fail'"
    path = Gem::Version.new(Minitest::VERSION) >= Gem::Version.new("5.21.0") ? "test/minitest/retry_test.rb" : __FILE__
    expect = <<-EOS
[MinitestRetry] retry 'fail' count: 1,  msg: RuntimeError: parsing error\n    #{path}:45:in #{failed_method_name}
[MinitestRetry] retry 'fail' count: 2,  msg: RuntimeError: parsing error\n    #{path}:45:in #{failed_method_name}
[MinitestRetry] retry 'fail' count: 3,  msg: RuntimeError: parsing error\n    #{path}:45:in #{failed_method_name}
    EOS

    refute reporter.passed?
    assert_equal expect, output
  end

  def test_if_test_is_successful_in_middle_of_retry
    output = capture_stdout do
      retry_test = Class.new(Minitest::Test) do
        @@counter = 0
        Minitest::Retry.use!
        def fail
          @@counter += 1
          assert_equal 3, @@counter
        end
      end
      Minitest::Runnable.run_one_method(retry_test, :fail, self.reporter)
    end
    expect = <<-EOS
[MinitestRetry] retry 'fail' count: 1,  msg: Expected: 3
  Actual: 1
[MinitestRetry] retry 'fail' count: 2,  msg: Expected: 3
  Actual: 2
    EOS

    assert reporter.passed?
    assert_equal expect, output
  end

  def test_having_to_only_specified_count_retry
    output = capture_stdout do
      retry_test = Class.new(Minitest::Test) do
        Minitest::Retry.use!(retry_count: 5)
        def fail
          assert false, 'fail test'
        end
      end
      Minitest::Runnable.run_one_method(retry_test, :fail, self.reporter)
    end
    expect = <<-EOS
[MinitestRetry] retry 'fail' count: 1,  msg: fail test
[MinitestRetry] retry 'fail' count: 2,  msg: fail test
[MinitestRetry] retry 'fail' count: 3,  msg: fail test
[MinitestRetry] retry 'fail' count: 4,  msg: fail test
[MinitestRetry] retry 'fail' count: 5,  msg: fail test
    EOS

    refute reporter.passed?
    assert_equal expect, output
  end

  def test_msg_does_not_display_when_verbose_false
    output = capture_stdout do
      retry_test = Class.new(Minitest::Test) do
        @@counter = 0
        Minitest::Retry.use!(verbose: false)
        def fail
          @@counter += 1
          assert_equal 3, @@counter
        end
      end
      Minitest::Runnable.run_one_method(retry_test, :fail, self.reporter)
    end

    assert reporter.passed?
    assert_empty output
  end

  def test_msg_does_not_display_when_do_not_use_retry
    output = capture_stdout do
      retry_test = Class.new(Minitest::Test) do
        def fail
          assert false, 'fail test'
        end
      end
      Minitest::Runnable.run_one_method(retry_test, :fail, self.reporter)
    end

    refute reporter.passed?
    assert_empty output
  end

  def test_donot_retry_skipped_Test
    output = capture_stdout do
      retry_test = Class.new(Minitest::Test) do
        Minitest::Retry.use!
        def skip_test
          skip 'skip test'
        end
      end
      Minitest::Runnable.run_one_method(retry_test, :skip_test, self.reporter)
    end

    assert reporter.passed?
    assert_empty output
  end

  def test_retry_when_error_in_exceptions_to_retry
    capture_stdout do
      retry_test = Class.new(Minitest::Test) do
        @@counter = 0
        def self.counter
          @@counter
        end
        Minitest::Retry.use! exceptions_to_retry: [TestError]
        def raise_test_error
          @@counter += 1
          raise TestError, 'This triggers a retry.'
        end
      end
      Minitest::Runnable.run_one_method(retry_test, :raise_test_error, self.reporter)

      assert_equal 4, retry_test.counter
    end
  end

  def test_donot_retry_when_not_in_exceptions_to_retry
    capture_stdout do
      retry_test = Class.new(Minitest::Test) do
        @@counter = 0
        def self.counter
          @@counter
        end
        Minitest::Retry.use! exceptions_to_retry: [TestError]
        def raise_test_error
          @@counter += 1
          raise ArgumentError, 'This does not trigger a retry.'
        end
      end
      Minitest::Runnable.run_one_method(retry_test, :raise_test_error, reporter)

      assert_equal 1, retry_test.counter
    end
  end

  def test_retry_when_method_in_methods_to_retry
    capture_stdout do
      retry_test = Class.new(Minitest::Test) do
        @@counter = 0

        class << self
          def name
            'TestClass'
          end
        end

        def self.counter
          @@counter
        end
        Minitest::Retry.use! methods_to_retry: ["TestClass#fail"]
        def fail
          @@counter += 1
          assert false, 'fail test'
        end
      end
      Minitest::Runnable.run_one_method(retry_test, :fail, self.reporter)

      assert_equal 4, retry_test.counter
    end
  end

  def test_donot_retry_when_not_in_methods_to_retry
    capture_stdout do
      retry_test = Class.new(Minitest::Test) do
        @@counter = 0

        class << self
          def name
            'TestClass'
          end
        end

        def self.counter
          @@counter
        end
        Minitest::Retry.use! methods_to_retry: ["TestClass#fail"]
        def another_fail
          @@counter += 1
          assert false, 'fail test'
        end
      end
      Minitest::Runnable.run_one_method(retry_test, :another_fail, self.reporter)

      assert_equal 1, retry_test.counter
    end
  end

  def test_retry_when_class_in_classes_to_retry
    capture_stdout do
      retry_test = Class.new(Minitest::Test) do
        @@counter = 0

        class << self
          def name
            'TestClass'
          end
        end

        def self.counter
          @@counter
        end
        Minitest::Retry.use! classes_to_retry: ["Minitest::Test"]
        def fail
          @@counter += 1
          assert false, 'fail test'
        end
      end
      Minitest::Runnable.run_one_method(retry_test, :fail, self.reporter)

      assert_equal 4, retry_test.counter
    end
  end

  def test_donot_retry_when_not_in_classes_to_retry
    capture_stdout do
      retry_test = Class.new(Minitest::Test) do
        @@counter = 0

        class << self
          def name
            'TestClass'
          end
        end

        def self.counter
          @@counter
        end
        Minitest::Retry.use! classes_to_retry: ["OtherClass"]
        def another_fail
          @@counter += 1
          assert false, 'fail test'
        end
      end
      Minitest::Runnable.run_one_method(retry_test, :another_fail, self.reporter)

      assert_equal 1, retry_test.counter
    end
  end

  def test_run_failure_callback_on_failure
    on_failure_block_has_ran = false
    test_name, test_class, retry_test, result_in_callback = nil
    capture_stdout do
      retry_test = Class.new(Minitest::Test) do
        Minitest::Retry.use!
        Minitest::Retry.on_failure do |klass, failed_test, result|
          on_failure_block_has_ran = true
          test_class = klass
          test_name = failed_test
          result_in_callback = result
        end

        def fail
          assert false, 'fail test'
        end
      end
      Minitest::Runnable.run_one_method(retry_test, :fail, self.reporter)
    end
    assert_equal :fail, test_name
    assert_equal retry_test, test_class
    assert on_failure_block_has_ran
    refute_nil result_in_callback
    assert_instance_of Minitest::Assertion, result_in_callback.failures[0]
  end

  def test_do_not_run_failure_callback_on_success
    on_failure_block_has_ran = false
    capture_stdout do
      retry_test = Class.new(Minitest::Test) do
        Minitest::Retry.use!
        Minitest::Retry.on_failure do
          on_failure_block_has_ran = true
        end

        def success
          assert true, 'success test'
        end
      end
      Minitest::Runnable.run_one_method(retry_test, :success, self.reporter)
    end
    refute on_failure_block_has_ran
  end

  def test_run_retry_callback_on_each_retry
    retry_counts, test_names, test_classes, results_in_callbacks = [], [], [], []
    retry_test = nil
    capture_stdout do
      retry_test = Class.new(Minitest::Test) do
        Minitest::Retry.use!
        Minitest::Retry.on_retry do |klass, test_name, retry_count, result|
          retry_counts << retry_count
          test_names << test_name
          test_classes << klass
          results_in_callbacks << result
        end

        def fail_sometimes
          assert_equal 3, 0
        end
      end
      Minitest::Runnable.run_one_method(retry_test, :fail_sometimes, self.reporter)
    end
    assert_equal [1, 2, 3], retry_counts
    assert_equal [:fail_sometimes] * 3, test_names
    assert_equal [retry_test] * 3, test_classes
    refute_empty results_in_callbacks
    assert_equal [Minitest::Assertion] * 3, results_in_callbacks.map{|x| x.failures[0].class}
  end

  def test_run_consistent_failure_callback_on_failure
    on_consistent_failure_block_call_count = 0
    test_name, test_class, retry_test, result_in_callback = nil
    capture_stdout do
      retry_test = Class.new(Minitest::Test) do
        Minitest::Retry.use!
        Minitest::Retry.on_consistent_failure do |klass, failed_test, result|
          on_consistent_failure_block_call_count += 1
          test_class = klass
          test_name = failed_test
          result_in_callback = result
        end

        def fail
          assert false, 'fail test'
        end
      end
      Minitest::Runnable.run_one_method(retry_test, :fail, self.reporter)
    end
    assert_equal :fail, test_name
    assert_equal retry_test, test_class
    assert_equal 1, on_consistent_failure_block_call_count
    refute_nil result_in_callback
    assert_instance_of Minitest::Assertion, result_in_callback.failures[0]
  end

  class TestError < StandardError; end
end
