# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
require 'test_helper'

class ShellContextTest < Minitest::Test

  def test_starts_not_done
    ctx = ShellContext.new
    refute ctx.done
  end

  def test_get_on_an_unset_key_returns_an_empty_array
    ctx = ShellContext.new
    assert_equal [], ctx.get( :missing )
  end

  def test_set_and_get_round_trip
    ctx = ShellContext.new
    ctx.set( :name, 'value' )
    assert_equal 'value', ctx.get( :name )
  end

  def test_set_and_get_accept_string_keys_interchangeably_with_symbols
    ctx = ShellContext.new
    ctx.set( 'name', 'value' )
    assert_equal 'value', ctx.get( :name )
  end

  def test_has_reflects_whether_a_key_was_set
    ctx = ShellContext.new
    refute ctx.has?( :name )
    ctx.set( :name, 'value' )
    assert ctx.has?( :name )
  end

  def test_keys_returns_every_set_key_as_a_symbol
    ctx = ShellContext.new
    ctx.set( :a, 1 )
    ctx.set( :b, 2 )
    assert_equal [ :a, :b ], ctx.keys
  end

  def test_add_to_list_creates_a_list_on_first_use
    ctx = ShellContext.new
    ctx.add_to_list( :items, 'one' )
    assert_equal [ 'one' ], ctx.get( :items )
  end

  def test_add_to_list_appends_to_an_existing_list
    ctx = ShellContext.new
    ctx.add_to_list( :items, 'one' )
    ctx.add_to_list( :items, 'two' )
    assert_equal [ 'one', 'two' ], ctx.get( :items )
  end

  def test_add_to_list_discards_a_non_array_existing_value
    ctx = ShellContext.new
    ctx.set( :items, 'not a list' )
    ctx.add_to_list( :items, 'one' )
    assert_equal [ 'one' ], ctx.get( :items )
  end

  # ---------------------------------------------------------------------
  #    Dynamic property access (method_missing)
  # ---------------------------------------------------------------------

  def test_dynamic_getter_returns_an_empty_array_when_unset
    ctx = ShellContext.new
    assert_equal [], ctx.projects
  end

  def test_dynamic_setter_and_getter_round_trip
    ctx = ShellContext.new
    ctx.projects = [ 'a', 'b' ]
    assert_equal [ 'a', 'b' ], ctx.projects
  end

  def test_respond_to_reflects_whether_a_key_was_set
    ctx = ShellContext.new
    refute ctx.respond_to?( :projects )
    ctx.projects = [ 'a' ]
    assert ctx.respond_to?( :projects )
  end

end
