# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
require 'test_helper'
require 'tmpdir'

class TestFilesTest < BaseEngineTest

  def test_starts_empty
    files = TestFiles.new( @engine, [] )
    assert_equal 0, files.count
  end

  def test_add_increases_the_count
    files = TestFiles.new( @engine, [] )
    files.add( 'whatever.test.gloo' )
    assert_equal 1, files.count
  end

  def test_each_yields_every_added_file
    files = TestFiles.new( @engine, [] )
    files.add( 'a.test.gloo' )
    files.add( 'b.test.gloo' )

    seen = []
    files.each { |f| seen << f }
    assert_equal 2, seen.count
    assert_kind_of TestFile, seen.first
  end

  def test_detect_files_finds_test_gloo_files_in_a_given_directory
    Dir.mktmpdir do |dir|
      File.write( File.join( dir, 'sample.test.gloo' ), '' )
      File.write( File.join( dir, 'not_a_test_file.gloo' ), '' )

      files = TestFiles.new( @engine, [ dir ] )
      files.detect_files

      assert_equal 1, files.count
    end
  end

  def test_detect_files_finds_test_gloo_files_recursively
    Dir.mktmpdir do |dir|
      nested = File.join( dir, 'nested' )
      Dir.mkdir( nested )
      File.write( File.join( dir, 'a.test.gloo' ), '' )
      File.write( File.join( nested, 'b.test.gloo' ), '' )

      files = TestFiles.new( @engine, [ dir ] )
      files.detect_files

      assert_equal 2, files.count
    end
  end

  def test_use_input_files_accepts_a_single_file_directly
    Dir.mktmpdir do |dir|
      path = File.join( dir, 'sample.test.gloo' )
      File.write( path, '' )

      files = TestFiles.new( @engine, [ path ] )
      files.detect_files

      assert_equal 1, files.count
    end
  end

  def test_randomize_keeps_the_same_files_present
    files = TestFiles.new( @engine, [] )
    files.add( 'a.test.gloo' )
    files.add( 'b.test.gloo' )
    files.add( 'c.test.gloo' )

    files.randomize
    assert_equal 3, files.count
  end

end
