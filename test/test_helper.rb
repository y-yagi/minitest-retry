$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'minitest/retry'
Minitest::Retry.use!
require 'pry'
require 'minitest/autorun'

