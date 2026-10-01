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

  #
  # Build a result that logged the given errors and warnings.
  #
  def build_logged_result( errors: 0, warnings: 0, expect_errors: false )
    result = build_result( passed: true )
    result.error_count = errors
    result.warning_count = warnings
    result.expect_errors = expect_errors
    return result
  end

  #
  # Log the given number of errors and warnings, as the tests would have.
  #
  def log_counts( errors: 0, warnings: 0 )
    capture_io do
      errors.times { @engine.log.error 'an error' }
      warnings.times { @engine.log.warn 'a warning' }
    end
  end

  #
  # Nothing logged: no summary.
  #
  def test_logged_summary_is_nil_when_nothing_was_logged
    @engine.log.reset_counts
    results = Results.new( @engine )
    results.add_result( build_logged_result )

    assert_nil results.get_logged_summary
  end

  #
  # A test that logged errors is named, with the counts and the log path.
  #
  def test_logged_summary_names_the_test_that_logged
    @engine.log.reset_counts
    log_counts( errors: 2, warnings: 1 )
    results = Results.new( @engine )
    result = build_logged_result( errors: 2, warnings: 1 )
    results.add_result( result )

    summary = results.get_logged_summary
    assert_includes summary, '2 errors and 1 warning logged during the run'
    assert_includes summary, File.basename( @engine.log.err_file )
    assert_includes summary, "#{result.pn} (2 errors and 1 warning)"
    refute_includes summary, 'outside tests'
  end

  #
  # Errors in a test that expects them leave no summary.
  #
  def test_logged_summary_leaves_out_expected_errors
    @engine.log.reset_counts
    log_counts( errors: 3 )
    results = Results.new( @engine )
    results.add_result( build_logged_result( errors: 3, expect_errors: true ) )

    assert_nil results.get_logged_summary
  end

  #
  # Errors logged outside any test get their own line.
  #
  def test_logged_summary_reports_errors_outside_tests
    @engine.log.reset_counts
    log_counts( errors: 1 )
    results = Results.new( @engine )
    results.add_result( build_logged_result )

    summary = results.get_logged_summary
    assert_includes summary, '1 error logged during the run'
    assert_includes summary, '(outside tests: 1 error)'
  end

  #
  # Counts read naturally: singular, plural, and zero parts left out.
  #
  def test_count_phrase_wording
    results = Results.new( @engine )
    assert_equal '1 error', results.count_phrase( 1, 0 )
    assert_equal '2 warnings', results.count_phrase( 0, 2 )
    assert_equal '2 errors and 1 warning', results.count_phrase( 2, 1 )
  end

end
