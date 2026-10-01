# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
require 'test_helper'

class ResultTest < BaseEngineTest

  def create_test_obj
    i = @engine.parser.parse_immediate 'create t as test'
    i.run
    return @engine.heap.root.find_child( 't' )
  end

  def test_starts_passed_with_zero_counts
    result = Result.new( @engine, create_test_obj )
    assert result.passed
    assert_equal 0, result.assert_count
    assert_equal 0, result.refute_count
  end

  def test_captures_the_tests_description_and_path_at_construction
    t = create_test_obj
    i = @engine.parser.parse_immediate "put 'a real description' into t.description"
    i.run

    result = Result.new( @engine, t )
    assert_equal 'a real description', result.instance_variable_get( :@test_desc )
    assert_equal t.pn, result.instance_variable_get( :@pn )
  end

  def test_add_message_accumulates_into_the_failure_message
    result = Result.new( @engine, create_test_obj )
    result.add_message( 'first problem' )
    result.add_message( 'second problem' )

    msg = result.instance_variable_get( :@failure_msg )
    assert_includes msg, 'first problem'
    assert_includes msg, 'second problem'
  end

  def test_passed_is_writable
    result = Result.new( @engine, create_test_obj )
    result.passed = false
    refute result.passed
  end

  #
  # A new result has logged nothing.
  #
  def test_starts_with_nothing_logged
    result = Result.new( @engine, create_test_obj )
    assert_equal 0, result.error_count
    assert_equal 0, result.warning_count
    refute result.expect_errors
    refute result.unexpected_logs?
  end

  #
  # Errors or warnings the test didn't declare are unexpected.
  #
  def test_unexpected_logs_when_errors_or_warnings_were_logged
    result = Result.new( @engine, create_test_obj )
    result.warning_count = 1
    assert result.unexpected_logs?
  end

  #
  # Errors in a test that expects them aren't unexpected.
  #
  def test_no_unexpected_logs_when_the_test_expects_errors
    result = Result.new( @engine, create_test_obj )
    result.error_count = 2
    result.expect_errors = true
    refute result.unexpected_logs?
  end

  #
  # A test meant to fail passes when an assertion failed.
  #
  def test_expect_failure_passes_a_failed_result
    result = Result.new( @engine, create_test_obj )
    result.passed = false
    result.expect_failure
    assert result.passed
  end

  #
  # A test meant to fail fails, with a message, when nothing failed.
  #
  def test_expect_failure_fails_a_passed_result
    result = Result.new( @engine, create_test_obj )
    result.expect_failure
    refute result.passed
    msg = result.instance_variable_get( :@failure_msg )
    assert_includes msg, Result::EXPECTED_FAIL_MSG
  end

end
