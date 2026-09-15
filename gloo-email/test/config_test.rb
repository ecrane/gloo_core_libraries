# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
require 'test_helper'

class ConfigTest < Minitest::Test

  def test_holds_the_given_values
    c = Config.new( 'smtp.example.com', '587', 'me@example.com', 'secret' )

    assert_equal 'smtp.example.com', c.host
    assert_equal '587', c.port
    assert_equal 'me@example.com', c.username
    assert_equal 'secret', c.password
  end

  def test_accessors_are_writable
    c = Config.new( 'a', 'b', 'c', 'd' )
    c.host = 'changed'
    assert_equal 'changed', c.host
  end

end
