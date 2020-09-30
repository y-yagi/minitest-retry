# Minitest::Retry

Re-run the test when the test fails.

![](https://github.com/y-yagi/minitest-retry/workflows/CI/badge.svg)
[![Gem Version](https://badge.fury.io/rb/minitest-retry.svg)](http://badge.fury.io/rb/minitest-retry)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'minitest-retry'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install minitest-retry

## Usage

In your `test_helper.rb` file, add the following lines:

```ruby
require 'minitest/retry'
Minitest::Retry.use!
```

Options can be specified to `use!` method. Can specify options are as follows:

```ruby
Minitest::Retry.use!(
  retry_count:  3,         # The number of times to retry. The default is 3.
  verbose: true,           # Whether or not to display the message at the time of retry. The default is true.
  io: $stdout,             # Display destination of retry when the message. The default is stdout.
  exceptions_to_retry: []  # List of exceptions that will trigger a retry (when empty, all exceptions will).
)
```

#### Policy Callbacks

These are optional in nature (useful to implement fine-grained policies).

The `should_skip` callback is executed before a test is run:
```ruby
Minitest::Retry.should_skip do |klass, test_name|
  # returning anything except nil/false will skip the test
end
```

#### Callbacks
The `on_failure` callback is executed each time a test fails:
```ruby
Minitest::Retry.on_failure do |klass, test_name, result|
  # code omitted
end
```

The `on_consistent_failure` callback is executed when a test consistently fails:
```ruby
Minitest::Retry.on_consistent_failure do |klass, test_name, result|
  # code omitted
end
```

The `on_retry` callback is executed each time a test is retried:
```ruby
Minitest::Retry.on_retry do |klass, test_name, retry_count, result|
  # code omitted
end
```

## Example

```ruby

Minitest::Retry.use!

class Minitest::RetryTest < Minitest::Test
  def test_fail
    assert false, 'test fail'
  end
end
```

```console
# Running:

[MinitestRetry] retry 'test_fail' count: 1,  msg: test fail
[MinitestRetry] retry 'test_fail' count: 2,  msg: test fail
[MinitestRetry] retry 'test_fail' count: 3,  msg: test fail
F

Finished in 0.002479s, 403.4698 runs/s, 403.4698 assertions/s.

  1) Failure:
Minitest::RetryTest#test_fail [test/minitest/sample_test.rb:6]:
test fail
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/y-yagi/minitest-retry.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
