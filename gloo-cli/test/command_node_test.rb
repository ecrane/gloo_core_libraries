# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
require 'test_helper'

class CommandNodeTest < Minitest::Test

  def test_defaults
    n = CommandNode.new( 'go' )
    assert_equal 'go', n.name
    assert_equal '', n.description
    assert_nil n.method
    assert_nil n.obj
  end

  def test_full_attributes
    obj = Object.new
    n = CommandNode.new( 'go', description: 'Run it', method: 'cmd_go', obj: obj )
    assert_equal 'go', n.name
    assert_equal 'Run it', n.description
    assert_equal 'cmd_go', n.method
    assert_same obj, n.obj
  end

  def test_children_is_empty_without_a_block
    n = CommandNode.new( 'go' )
    assert_equal [], n.children( nil )
  end

  def test_children_calls_the_block_with_the_given_context
    seen_context = nil
    n = CommandNode.new( 'go' ) do |ctx|
      seen_context = ctx
      [ CommandNode.new( 'sub' ) ]
    end

    context = Object.new
    result = n.children( context )

    assert_same context, seen_context
    assert_equal 1, result.count
    assert_equal 'sub', result.first.name
  end

end
