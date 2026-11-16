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

  LOADS_MD = <<~GLOO.freeze
    load lib md
    tests.loads_md [can] :
      has_md [test] :
        description [string] : Loads md for itself.
        on_test [script] :
          exists? object markdown
          assert "markdown after load lib md"
  GLOO

  EXPECTS_MD = <<~GLOO.freeze
    tests.expects_md [can] :
      has_md [test] :
        description [string] : Uses markdown without loading md.
        on_test [script] :
          exists? object markdown
          assert "markdown without loading md"
  GLOO

  NO_MD = <<~GLOO.freeze
    tests.no_md [can] :
      no_md [test] :
        description [string] : Sees no library it didn't load.
        on_test [script] :
          exists? object markdown
          refute "no markdown from an earlier file"
  GLOO

  SKIPPED_FAIL = <<~GLOO.freeze
    tests.runner_skip [can] :
      skipped [test] :
        description [string] : Would fail, but is skipped.
        skip [bool] : true
        on_test [script] :
          eval 1 = 2
          assert "never runs"
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

  def test_a_library_loaded_by_one_file_is_gone_in_the_next
    keeping_the_dictionary_as_it_was do
      md = @dic.find_obj( 'markdown' )
      @dic.unregister_obj( md ) if md

      results = run_in_order( 'a.test.gloo' => LOADS_MD, 'b.test.gloo' => NO_MD )
      assert_equal 2, results.pass_count
      assert_equal 0, results.fail_count
    end
  end

  def test_a_pinned_library_stays_loaded_between_files
    keeping_the_dictionary_as_it_was do
      @engine.lib_manager.load_lib 'md', pinned: true

      results = run_in_order( 'a.test.gloo' => EXPECTS_MD, 'b.test.gloo' => EXPECTS_MD )
      assert_equal 2, results.pass_count
      assert_equal 0, results.fail_count
    end
  end

  def test_run_returns_true_when_a_failing_test_is_skipped
    assert_equal true, run_files( 'a.test.gloo' => PASSING, 'b.test.gloo' => SKIPPED_FAIL )
  end

  private

  #
  # Write the given test files (name => source) to a scratch folder and
  # run them one after another, in the order given, as the runner runs
  # each file (with the reset between files); return the results.
  #
  def run_in_order( files )
    dir = Dir.mktmpdir
    paths = files.map do |name, src|
      path = File.join( dir, name )
      File.write( path, src )
      path
    end
    runner = TestRunner.new( @engine, [ dir ] )
    capture_io do
      paths.each { |path| runner.run_one_file( TestFile.new( @engine, path ) ) }
    end
    return runner.instance_variable_get( :@results )
  ensure
    FileUtils.remove_entry dir if dir
  end

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
