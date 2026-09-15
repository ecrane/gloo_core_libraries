# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
require 'test_helper'

class ResultsTest < BaseEngineTest

  def create_test_obj
    i = @engine.parser.parse_immediate 'create t as test'
    i.run
    return @engine.heap.root.find_child( 't' )
  end

  def build_result( passed:, assert_count: 0, refute_count: 0 )
    result = Result.new( @engine, create_test_obj )
    result.passed = passed
    result.assert_count = assert_count
    result.refute_count = refute_count
    return result
  end

  def test_starts_at_zero
    results = Results.new( @engine )
    assert_equal 0, results.file_count
    assert_equal 0, results.pass_count
    assert_equal 0, results.fail_count
    assert_equal 0, results.assert_count
  end

  def test_add_result_counts_a_pass
    results = Results.new( @engine )
    results.add_result( build_result( passed: true, assert_count: 2 ) )

    assert_equal 1, results.pass_count
    assert_equal 0, results.fail_count
    assert_equal 2, results.assert_count
  end

  def test_add_result_counts_a_failure
    results = Results.new( @engine )
    results.add_result( build_result( passed: false, assert_count: 1 ) )

    assert_equal 0, results.pass_count
    assert_equal 1, results.fail_count
    assert_equal 1, results.assert_count
  end

  def test_add_result_sums_assert_and_refute_counts_together
    results = Results.new( @engine )
    results.add_result( build_result( passed: true, assert_count: 2, refute_count: 3 ) )

    assert_equal 5, results.assert_count
  end

  def test_duration_reflects_the_timed_interval
    results = Results.new( @engine )
    results.start_timer
    results.end_timer

    assert_operator results.duration, :>=, 0
  end

  def test_get_result_summary_includes_pass_and_fail_counts
    results = Results.new( @engine )
    results.add_result( build_result( passed: true, assert_count: 1 ) )
    results.add_result( build_result( passed: false, assert_count: 1 ) )

    summary = results.get_result_summary
    assert_includes summary, 'Tests: 2'
    assert_includes summary, 'Passed: 1'
    assert_includes summary, 'Failed: 1'
    assert_includes summary, 'Assertions: 2'
  end

end
