require "minitest/retry/version"

module Minitest
  module Retry
    def self.use!(retry_count: 3, io: $stdout, verbose: true)
      @retry_count, @io, @verbose = retry_count, io, verbose
      Minitest.prepend(self)
    end

    def self.retry_count
      @retry_count
    end

    def self.io
      @io
    end

    def self.verbose
      @verbose
    end

    module ClassMethods
      def run_one_method(klass, method_name)
        retry_count = Minitest::Retry.retry_count
        result = super(klass, method_name)
        unless result.failures.empty?
          retry_count.times do |count|
            if Minitest::Retry.verbose && Minitest::Retry.io
              msg = "[MiniestRetry] retry '%s' count: %s,  msg: %s\n" %
                [method_name, count + 1, result.failures.join(",")]
              Minitest::Retry.io.puts(msg)
            end

            result = super(klass, method_name)
            break if result.failures.empty?
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
