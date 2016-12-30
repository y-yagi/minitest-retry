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

  class TestError < StandardError; end
end

MiniTest::Test.include RetryTest
