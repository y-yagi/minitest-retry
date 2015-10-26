# Minitest::Retry

Re-run the test when the test fails.

[![Build Status](https://travis-ci.org/y-yagi/minitest-retry.svg?branch=master)](https://travis-ci.org/y-yagi/minitest-retry)
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
  retry_count:  3  # The number of times to retry. The default is 3.
  verbose: true    # Whether or not to display the message at the time of retry. The default is true.
  io: $stdout      # Display destination of retry when the message. The default is stdout.
)
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
