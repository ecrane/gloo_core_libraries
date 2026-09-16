# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
require 'test_helper'

class RefuteTest < BaseEngineTest

  #
  # refute (like assert) only does real work when a Result is the
  # engine's current context object - see AssertTest#build_result.
  #
  def build_result
    i = @engine.parser.parse_immediate 'create t as test'
    i.run
    t = @engine.heap.root.find_child( 't' )
    return Result.new( @engine, t )
  end

  def test_the_keyword
    assert_equal 'refute', Refute.keyword
  end

  def test_the_keyword_shortcut
    assert_equal 'expect_not', Refute.keyword_shortcut
  end

  def test_doc_data
    data = Refute.doc_data
    assert_equal Refute.keyword, data[ :name ]
    assert_equal Refute.keyword_shortcut, data[ :shortcut ]
  end

  def test_passes_when_it_is_false
    @engine.context_object = build_result

    i = @engine.parser.parse_immediate 'eval false'
    i.run
    i = @engine.parser.parse_immediate 'refute'
    i.run

    assert @engine.context_object.passed
    assert_equal 1, @engine.context_object.refute_count
  end

  def test_fails_when_it_is_true
    @engine.context_object = build_result

    i = @engine.parser.parse_immediate 'eval true'
    i.run
    i = @engine.parser.parse_immediate 'refute'
    i.run

    refute @engine.context_object.passed
    assert_equal 1, @engine.context_object.refute_count
  end

  def test_failure_records_the_default_message
    @engine.context_object = build_result

    i = @engine.parser.parse_immediate 'eval true'
    i.run
    i = @engine.parser.parse_immediate 'refute'
    i.run

    msg = @engine.context_object.instance_variable_get( :@failure_msg )
    assert_includes msg, 'Refutation failed'
  end

  def test_failure_records_a_custom_message
    @engine.context_object = build_result

    i = @engine.parser.parse_immediate 'eval true'
    i.run
    i = @engine.parser.parse_immediate "refute 'expected the thing to not happen'"
    i.run

    msg = @engine.context_object.instance_variable_get( :@failure_msg )
    assert_includes msg, 'expected the thing to not happen'
  end

  def test_the_short_keyword_behaves_the_same_as_refute
    @engine.context_object = build_result

    i = @engine.parser.parse_immediate 'eval false'
    i.run
    i = @engine.parser.parse_immediate 'expect_not'
    i.run

    assert @engine.context_object.passed
  end

end
