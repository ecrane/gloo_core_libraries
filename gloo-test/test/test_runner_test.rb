# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
require 'test_helper'
require 'tmpdir'

class TestRunnerTest < BaseEngineTest

  PASSING = <<~GLOO.freeze
    tests.runner_pass [can] :
      passes [test] :
        description [string] : Always passes.
        on_test [script] :
          eval 1 = 1
          assert "one is one"
  GLOO

  FAILING = <<~GLOO.freeze
    tests.runner_fail [can] :
      fails [test] :
        description [string] : Always fails.
        on_test [script] :
          eval 1 = 2
          assert "meant to fail"
  GLOO

  UNEXPECTED_ERROR = <<~GLOO.freeze
    tests.runner_error [can] :
      logs_an_error [test] :
        description [string] : Passes, but logs an error it didn't expect.
        on_test [script] :
          load no_such_file_xyz
          eval 1 = 1
          assert "one is one"
  GLOO

  EXPECTED_ERROR = <<~GLOO.freeze
    tests.runner_expected [can] :
      logs_an_expected_error [test] :
        description [string] : Passes, and expects the error it logs.
        expect_errors [bool] : true
        on_test [script] :
          load no_such_file_xyz
          eval 1 = 1
          assert "one is one"
  GLOO

  def test_run_returns_true_when_every_test_passes
    assert_equal true, run_files( 'a.test.gloo' => PASSING )
  end

  def test_run_returns_false_when_a_test_fails
    assert_equal false, run_files( 'a.test.gloo' => PASSING, 'b.test.gloo' => FAILING )
  end

  def test_run_returns_false_for_an_unexpected_error
    assert_equal false, run_files( 'a.test.gloo' => UNEXPECTED_ERROR )
  end

  def test_run_returns_true_for_an_expected_error
    assert_equal true, run_files( 'a.test.gloo' => EXPECTED_ERROR )
  end

  def test_run_returns_false_for_a_missing_path
    result = nil
    capture_io do
      result = TestRunner.new( @engine, [ '/tmp/gloo_no_such_tests_xyz' ] ).run
    end
    assert_equal false, result
  end

  private

  #
  # Write the given test files (name => source) to a scratch folder,
  # run them, and return what TestRunner#run returns.
  #
  def run_files( files )
    dir = Dir.mktmpdir
    files.each { |name, src| File.write( File.join( dir, name ), src ) }
    result = nil
    capture_io { result = TestRunner.new( @engine, [ dir ] ).run }
    return result
  ensure
    FileUtils.remove_entry dir if dir
  end

end
