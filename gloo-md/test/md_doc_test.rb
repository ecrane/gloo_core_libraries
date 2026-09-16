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

  def test_read_with_a_blank_path_does_nothing
    d = create_doc
    d.msg_read

    fm = d.find_child( 'frontmatter' )
    assert_equal 0, fm.child_count
  end

  def test_read_with_a_missing_file_logs_and_returns_without_raising
    d = create_doc
    d.find_child( 'path' ).set_value( '/tmp/does_not_exist_gloo_md_doc.md' )

    d.msg_read # should not raise
    fm = d.find_child( 'frontmatter' )
    assert_equal 0, fm.child_count
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

end
