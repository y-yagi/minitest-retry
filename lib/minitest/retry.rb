require "minitest/retry/version"

module Minitest
  module Retry
    class << self
      def use!(retry_count: 3, io: $stdout, verbose: true, exceptions_to_retry: [], methods_to_retry: [], classes_to_retry: [], methods_to_skip: [], exceptions_to_skip: [])
        @retry_count, @io, @verbose, @exceptions_to_retry, @methods_to_retry, @classes_to_retry, @methods_to_skip, @exceptions_to_skip = retry_count, io, verbose, exceptions_to_retry, methods_to_retry, classes_to_retry, methods_to_skip, exceptions_to_skip
        @failure_callback, @consistent_failure_callback, @retry_callback = nil, nil, nil
        Minitest.prepend(self)
      end

      def on_failure(&block)
        return unless block_given?
        @failure_callback = block
      end

      def on_consistent_failure(&block)
        return unless block_given?
        @consistent_failure_callback = block
      end

      def on_retry(&block)
        return unless block_given?
        @retry_callback = block
      end

      def retry_count
        @retry_count
      end

      def io
        @io
      end

      def verbose
        @verbose
      end

      def exceptions_to_retry
        @exceptions_to_retry
      end

      def methods_to_retry
        @methods_to_retry
      end

      def classes_to_retry
        @classes_to_retry
      end

      def failure_callback
        @failure_callback
      end

      def consistent_failure_callback
        @consistent_failure_callback
      end

      def retry_callback
        @retry_callback
      end

      def methods_to_skip
        @methods_to_skip
      end

      def exceptions_to_skip
        @exceptions_to_skip
      end

      def failure_to_retry?(failures = [], klass_method_name, klass)
        return false if failures.empty?

        if methods_to_retry.any?
          return methods_to_retry.include?(klass_method_name)
        end

        if exceptions_to_retry.any?
          errors = failures.map(&:error).map(&:class)
          return (errors & exceptions_to_retry).any?
        end

        if methods_to_skip.any?
          return !methods_to_skip.include?(klass_method_name)
        end

        if exceptions_to_skip.any?
          errors = failures.map(&:error).map(&:class)
          return !(errors & exceptions_to_skip).any?
        end

        return true if classes_to_retry.empty?
        ancestors = klass.ancestors.map(&:to_s)
        return classes_to_retry.any? { |class_to_retry| ancestors.include?(class_to_retry) }
      end
    end

    module ClassMethods
      def run_one_method(klass, method_name)
        result = super(klass, method_name)

        klass_method_name = "#{klass.name}##{method_name}"
        return result unless Minitest::Retry.failure_to_retry?(result.failures, klass_method_name, klass)
        if !result.skipped?
          Minitest::Retry.failure_callback.call(klass, method_name, result) if Minitest::Retry.failure_callback
          Minitest::Retry.retry_count.times do |count|
            Minitest::Retry.retry_callback.call(klass, method_name, count + 1, result) if Minitest::Retry.retry_callback
            if Minitest::Retry.verbose && Minitest::Retry.io
              msg = "[MinitestRetry] retry '%s' count: %s,  msg: %s\n" %
                [method_name, count + 1, result.failures.map(&:message).join(",")]
              Minitest::Retry.io.puts(msg)
            end

            result = super(klass, method_name)
            break if result.failures.empty?
          end

          if Minitest::Retry.consistent_failure_callback && !result.failures.empty?
            Minitest::Retry.consistent_failure_callback.call(klass, method_name, result)
          end
        end
        result
      end
    end

    def self.prepended(base)
      class << base
        prepend ClassMethods
      end
    end
  end
end
