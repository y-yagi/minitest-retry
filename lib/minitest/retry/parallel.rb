module Minitest
  module Retry
    module ParallelExecutor
      def start
        @pool = Array.new(size) do
          Thread.new @queue do |queue|
            Thread.current.abort_on_exception = true

            while job = queue.pop do
              klass, method_name, reporter = job

              reporter.synchronize { reporter.prerecord klass, method_name }

              result = Minitest::Retry.run_with_retry(klass, method_name) do
                klass.new(method_name).run
              end

              reporter.synchronize { reporter.record result }
            end
          end
        end
      end
    end
  end
end
