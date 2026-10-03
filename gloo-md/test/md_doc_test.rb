# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
require 'test_helper'
require 'tmpdir'

class MdDocTest < BaseEngineTest

  def create_doc
    i = @engine.parser.parse_immediate 'create d as md_doc'
    i.run
    return @engine.heap.root.find_child( 'd' )
  end

  def fixture_path
    return File.expand_path( File.join( __dir__, 'fixtures', 'test_doc.md' ) )
  end

  def test_the_typename
    assert_equal 'md_doc', MdDoc.typename
  end

  def test_the_short_typename_is_the_same_as_the_typename
    assert_equal MdDoc.typename, MdDoc.short_typename
  end

  def test_doc_data
    data = MdDoc.doc_data
    assert_equal MdDoc.typename, data[ :name ]
    assert_equal MdDoc.short_typename, data[ :shortcut ]
  end

  def test_find_type
    assert @dic.find_obj( 'md_doc' )
  end

  def test_messages
    msgs = MdDoc.messages
    assert msgs.include?( 'read' )
    assert msgs.include?( 'write' )
  end

  def test_adds_children_on_create
    o = MdDoc.new( @engine )
    assert o.add_children_on_create?
  end

  def test_that_children_are_added_on_create
    d = create_doc
    assert_equal 3, d.child_count
    assert_equal 'path', d.children[ 0 ].name
    assert_equal 'frontmatter', d.children[ 1 ].name
    assert_equal 'body', d.children[ 2 ].name
  end

  def test_read_populates_frontmatter_children_from_scalar_yaml_values
    d = create_doc
    d.find_child( 'path' ).set_value( fixture_path )
    d.msg_read

    fm = d.find_child( 'frontmatter' )
    assert_equal 'Test Document', fm.find_child( 'title' ).value
    assert_equal 'draft', fm.find_child( 'state' ).value
  end

  def test_read_populates_the_body
    d = create_doc
    d.find_child( 'path' ).set_value( fixture_path )
    d.msg_read

    body = d.find_child( 'body' ).value
    assert_includes body, 'This is the body of the test document.'
  end

  #
  # Reading a second file replaces the frontmatter children with
  # exactly that file's keys.
  #
  def test_read_drops_frontmatter_keys_from_an_earlier_read
    d = create_doc
    d.find_child( 'path' ).set_value( fixture_path )
    d.msg_read
    d.find_child( 'path' ).set_value( fixture( 'other_doc.md' ) )
    d.msg_read

    fm = d.find_child( 'frontmatter' )
    assert_equal 'Other Document', fm.find_child( 'title' ).value
    assert_nil fm.find_child( 'state' )
    assert_equal 1, fm.child_count
  end

  #
  # Path to a fixture in the test fixtures folder.
  #
  def fixture( name )
    return File.expand_path( File.join( __dir__, 'fixtures', name ) )
  end

  #
  # A successful read puts true in it.
  #
  def test_read_puts_true_in_it
    d = create_doc
    d.find_child( 'path' ).set_value( fixture_path )
    d.msg_read

    assert_equal true, @engine.heap.it.value
    refute @engine.error?
  end

  #
  # A blank path is a runtime error; it is false and nothing changes.
  #
  def test_read_with_a_blank_path_is_an_error
    d = create_doc
    d.msg_read

    assert @engine.error?
    assert_equal Gloo::Core::Error::RUNTIME, @engine.heap.error.kind
    assert_includes @engine.heap.error.value, 'has no path'
    assert_equal false, @engine.heap.it.value
    assert_equal 0, d.find_child( 'frontmatter' ).child_count
  end

  #
  # A missing file is reported with the shared not-found wording.
  #
  def test_read_with_a_missing_file_is_an_error
    path = '/tmp/does_not_exist_gloo_md_doc.md'
    d = create_doc
    d.find_child( 'path' ).set_value( path )
    d.msg_read

    assert_equal Gloo::Core::NotFound.file( path ), @engine.heap.error.value
    assert_equal false, @engine.heap.it.value
    assert_equal 0, d.find_child( 'frontmatter' ).child_count
  end

  #
  # A date in the frontmatter reads as a string child.
  #
  def test_read_turns_a_date_into_a_string_child
    d = create_doc
    d.find_child( 'path' ).set_value( fixture( 'dated_doc.md' ) )
    d.msg_read

    refute @engine.error?
    assert_equal '2026-10-01', d.find_child( 'frontmatter' ).find_child( 'date' ).value
  end

  #
  # A time in the frontmatter reads as a string child.
  #
  def test_read_turns_a_time_into_a_string_child
    Dir.mktmpdir do |dir|
      path = File.join( dir, 'timed.md' )
      File.write( path, "---\nat: 2026-10-01 09:30:00\n---\nBody.\n" )
      d = create_doc
      d.find_child( 'path' ).set_value( path )
      d.msg_read

      refute @engine.error?
      assert_equal '2026-10-01 09:30:00 UTC', d.find_child( 'frontmatter' ).find_child( 'at' ).value
    end
  end

  #
  # Writing back an unchanged time keeps it as a YAML time, not a string.
  #
  def test_write_keeps_an_unchanged_time_as_written
    Dir.mktmpdir do |dir|
      path = File.join( dir, 'timed.md' )
      File.write( path, "---\ntitle: Timed\nat: 2026-10-01 09:30:00\n---\nBody.\n" )
      d = create_doc
      d.find_child( 'path' ).set_value( path )
      d.msg_read
      d.find_child( 'frontmatter' ).find_child( 'title' ).set_value( 'Changed' )
      d.msg_write

      content = File.read( path )
      refute_includes content, "'2026-10-01"
      assert_includes content, "at: 2026-10-01 09:30:00\n"
    end
  end

  #
  # Invalid frontmatter YAML is a runtime error; it is false.
  #
  def test_read_with_invalid_frontmatter_is_an_error
    d = create_doc
    d.find_child( 'path' ).set_value( fixture( 'bad_frontmatter.md' ) )
    d.msg_read

    assert @engine.error?
    assert_includes @engine.heap.error.value, "isn't valid YAML"
    assert_equal false, @engine.heap.it.value
  end

  #
  # Frontmatter that isn't key: value pairs is reported, not a crash.
  #
  def test_read_with_frontmatter_that_is_not_pairs_is_an_error
    Dir.mktmpdir do |dir|
      path = File.join( dir, 'list.md' )
      File.write( path, "---\n- one\n- two\n---\nBody.\n" )
      d = create_doc
      d.find_child( 'path' ).set_value( path )
      d.msg_read

      assert_includes @engine.heap.error.value, 'key: value pairs'
      assert_equal false, @engine.heap.it.value
    end
  end

  def test_write_then_read_round_trips_frontmatter_and_body
    Dir.mktmpdir do |dir|
      path = File.join( dir, 'roundtrip.md' )

      d = create_doc
      d.find_child( 'path' ).set_value( path )

      fm = d.find_child( 'frontmatter' )
      @engine.factory.create_string( 'title', 'Round Trip', fm )
      @engine.factory.create_string( 'state', 'active', fm )
      d.find_child( 'body' ).set_value( 'Round trip body text.' )

      d.msg_write
      assert File.exist?( path )

      d2 = create_doc
      d2.find_child( 'path' ).set_value( path )
      d2.msg_read

      fm2 = d2.find_child( 'frontmatter' )
      assert_equal 'Round Trip', fm2.find_child( 'title' ).value
      assert_equal 'active', fm2.find_child( 'state' ).value
      assert_equal 'Round trip body text.', d2.find_child( 'body' ).value
    end
  end

  def test_write_preserves_complex_frontmatter_values_not_represented_as_children
    Dir.mktmpdir do |dir|
      path = File.join( dir, 'with_array.md' )
      File.write( path, "---\ntitle: Has Array\ntags:\n  - one\n  - two\n---\nBody text.\n" )

      d = create_doc
      d.find_child( 'path' ).set_value( path )
      d.msg_read

      # Change the scalar title, then write back - the array-valued
      # 'tags' key was never turned into a child, so msg_write must
      # re-read the file to preserve it rather than dropping it.
      fm = d.find_child( 'frontmatter' )
      fm.find_child( 'title' ).set_value( 'Changed Title' )
      d.msg_write

      content = File.read( path )
      assert_includes content, 'Changed Title'
      assert_includes content, 'one'
      assert_includes content, 'two'
    end
  end

  def test_write_creates_the_file_if_it_does_not_exist
    Dir.mktmpdir do |dir|
      path = File.join( dir, 'brand_new.md' )
      refute File.exist?( path )

      d = create_doc
      d.find_child( 'path' ).set_value( path )
      d.find_child( 'body' ).set_value( 'New file body.' )
      d.msg_write

      assert File.exist?( path )
      assert_includes File.read( path ), 'New file body.'
    end
  end

  #
  # Writing back unchanged values keeps their YAML types: a date and
  # a number stay unquoted.
  #
  def test_write_keeps_unchanged_dates_and_numbers_as_written
    Dir.mktmpdir do |dir|
      path = File.join( dir, 'dated.md' )
      File.write( path, File.read( fixture( 'dated_doc.md' ) ) )
      d = create_doc
      d.find_child( 'path' ).set_value( path )
      d.msg_read
      d.find_child( 'frontmatter' ).find_child( 'title' ).set_value( 'Changed' )
      d.msg_write

      content = File.read( path )
      assert_includes content, 'date: 2026-10-01'
      assert_includes content, 'count: 3'
      assert_includes content, 'title: Changed'
    end
  end

  #
  # A blank path on write is an error, and nothing is written.
  #
  def test_write_with_a_blank_path_is_an_error
    d = create_doc
    d.msg_write
    assert_includes @engine.heap.error.value, 'has no path'
  end

  #
  # A write that fails (here, a missing folder) is reported, not raised.
  #
  def test_write_failure_is_an_error
    d = create_doc
    d.find_child( 'path' ).set_value( '/no/such/folder/gloo_md_doc.md' )
    d.msg_write

    assert @engine.error?
    assert_includes @engine.heap.error.value, 'Could not write'
  end

  #
  # A file with invalid frontmatter isn't overwritten by write.
  #
  def test_write_does_not_overwrite_invalid_frontmatter
    Dir.mktmpdir do |dir|
      path = File.join( dir, 'bad.md' )
      original = File.read( fixture( 'bad_frontmatter.md' ) )
      File.write( path, original )
      d = create_doc
      d.find_child( 'path' ).set_value( path )
      d.find_child( 'body' ).set_value( 'New body.' )
      d.msg_write

      assert_includes @engine.heap.error.value, "isn't valid YAML"
      assert_equal original, File.read( path )
    end
  end

end
