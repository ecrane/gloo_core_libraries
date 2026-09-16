# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
require 'test_helper'

class TestTest < BaseEngineTest

  def create_test
    i = @engine.parser.parse_immediate 'create t as test'
    i.run
    return @engine.heap.root.find_child( 't' )
  end

  def test_the_typename
    assert_equal 'test', Test.typename
  end

  def test_the_short_typename_is_the_same_as_the_typename
    assert_equal Test.typename, Test.short_typename
  end

  def test_doc_data
    data = Test.doc_data
    assert_equal Test.typename, data[ :name ]
    assert_equal Test.short_typename, data[ :shortcut ]
  end

  def test_find_type
    assert @dic.find_obj( 'test' )
  end

  def test_adds_children_on_create
    o = Test.new( @engine )
    assert o.add_children_on_create?
  end

  def test_that_children_are_added_on_create
    t = create_test
    assert_equal 2, t.child_count
    assert_equal 'description', t.children[ 0 ].name
    assert_equal 'on_test', t.children[ 1 ].name
  end

  def test_desc_defaults_to_unknown_without_a_description_child
    o = Test.new( @engine )
    assert_equal 'Unknown', o.test_desc
  end

  def test_desc_reads_the_description_child
    t = create_test
    i = @engine.parser.parse_immediate "put 'checks the thing' into t.description"
    i.run
    assert_equal 'checks the thing', t.test_desc
  end

  def test_run_test_returns_a_passing_result_when_the_script_asserts_true
    t = create_test
    o = t.find_child( 'on_test' )
    o.add_line( 'eval true' )
    o.add_line( 'assert' )

    # run_test prints a '.'/'x' progress symbol as a side effect (the
    # live dot shown during a real `gloo --test` run) - capture it so
    # it doesn't clutter this suite's own test output.
    result = nil
    capture_io { result = t.run_test }
    assert result.passed
    assert_equal 1, result.assert_count
  end

  def test_run_test_returns_a_failing_result_when_the_script_asserts_false
    t = create_test
    o = t.find_child( 'on_test' )
    o.add_line( 'eval false' )
    o.add_line( 'assert' )

    result = nil
    capture_io { result = t.run_test }
    refute result.passed
    assert_equal 1, result.assert_count
  end

  def test_run_test_clears_the_engines_context_object_when_done
    t = create_test
    capture_io { t.run_test }
    assert_nil @engine.context_object
  end

end
