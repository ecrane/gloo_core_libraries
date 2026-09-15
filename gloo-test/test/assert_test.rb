# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
require 'test_helper'

class AssertTest < BaseEngineTest

  #
  # assert (and refute) only do real work when a Result is the
  # engine's current context object - that's what Test#run_test sets
  # up before running a test's on_test script. Build one directly so
  # assert/refute can be exercised without a full Test run.
  #
  def build_result
    i = @engine.parser.parse_immediate 'create t as test'
    i.run
    t = @engine.heap.root.find_child( 't' )
    return Result.new( @engine, t )
  end

  def test_the_keyword
    assert_equal 'assert', Assert.keyword
  end

  def test_the_keyword_shortcut
    assert_equal 'expect', Assert.keyword_shortcut
  end

  def test_passes_when_it_is_true
    @engine.context_object = build_result

    i = @engine.parser.parse_immediate 'eval true'
    i.run
    i = @engine.parser.parse_immediate 'assert'
    i.run

    assert @engine.context_object.passed
    assert_equal 1, @engine.context_object.assert_count
  end

  def test_fails_when_it_is_false
    @engine.context_object = build_result

    i = @engine.parser.parse_immediate 'eval false'
    i.run
    i = @engine.parser.parse_immediate 'assert'
    i.run

    refute @engine.context_object.passed
    assert_equal 1, @engine.context_object.assert_count
  end

  def test_failure_records_the_default_message
    @engine.context_object = build_result

    i = @engine.parser.parse_immediate 'eval false'
    i.run
    i = @engine.parser.parse_immediate 'assert'
    i.run

    msg = @engine.context_object.instance_variable_get( :@failure_msg )
    assert_includes msg, 'Assertion failed'
  end

  def test_failure_records_a_custom_message
    @engine.context_object = build_result

    i = @engine.parser.parse_immediate 'eval false'
    i.run
    i = @engine.parser.parse_immediate "assert 'expected the thing to happen'"
    i.run

    msg = @engine.context_object.instance_variable_get( :@failure_msg )
    assert_includes msg, 'expected the thing to happen'
  end

  def test_the_short_keyword_behaves_the_same_as_assert
    @engine.context_object = build_result

    i = @engine.parser.parse_immediate 'eval true'
    i.run
    i = @engine.parser.parse_immediate 'expect'
    i.run

    assert @engine.context_object.passed
  end

  def test_assert_count_increments_once_per_call
    @engine.context_object = build_result

    i = @engine.parser.parse_immediate 'eval true'
    i.run
    3.times do
      i = @engine.parser.parse_immediate 'assert'
      i.run
    end

    assert_equal 3, @engine.context_object.assert_count
  end

end
