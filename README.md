# Minitest::Retry

Re-run the test when the test fails.

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

```ruby
require 'minitest/retry'
Minitest::Retry.use!(retry_count: 3)
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/y-yagi/minitest-retry.

