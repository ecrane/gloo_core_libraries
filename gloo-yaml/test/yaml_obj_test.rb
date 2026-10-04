# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
require 'test_helper'
require 'tmpdir'

class YamlObjTest < BaseEngineTest

  def create_yaml_obj
    i = @engine.parser.parse_immediate 'create y as yaml'
    i.run
    return @engine.heap.root.find_child( 'y' )
  end

  def create_container( parent_pn, *field_names )
    i = @engine.parser.parse_immediate "create #{parent_pn} as can"
    i.run
    field_names.each do |name|
      i = @engine.parser.parse_immediate "create #{parent_pn}.#{name} as string"
      i.run
    end
    return @engine.heap.root.find_child( parent_pn )
  end

  def test_the_typename
    assert_equal 'yaml', YamlObj.typename
  end

  def test_the_short_typename
    assert_equal 'yml', YamlObj.short_typename
  end

  def test_doc_data
    data = YamlObj.doc_data
    assert_equal YamlObj.typename, data[ :name ]
    assert_equal YamlObj.short_typename, data[ :shortcut ]
  end

  def test_find_type
    assert @dic.find_obj( 'yaml' )
    assert @dic.find_obj( 'yml' )
  end

  def test_messages
    msgs = YamlObj.messages
    assert msgs.include?( 'load' )
    assert msgs.include?( 'save' )
  end

  def test_does_not_add_children_on_create
    o = YamlObj.new( @engine )
    refute o.add_children_on_create?
  end

  #
  # Run a gloo command.
  #
  def run_cmd( cmd )
    @engine.parser.parse_immediate( cmd ).run
  end

  #
  # A yaml object pointing at a file with the given content, in a
  # temp folder; yields the object and the file's path.
  #
  def with_yaml_file( content )
    Dir.mktmpdir do |dir|
      path = File.join( dir, 'data.yaml' )
      File.write( path, content ) if content
      y = create_yaml_obj
      y.set_value( path )
      yield y, path
    end
  end

  #
  # load with no container is a syntax error; it is false.
  #
  def test_load_with_no_param_is_a_syntax_error
    y = create_yaml_obj
    y.set_value( '/does/not/matter.yaml' )
    run_cmd 'tell y to load'

    assert_equal Gloo::Core::Error::SYNTAX, @engine.heap.error.kind
    assert_equal false, @engine.heap.it.value
  end

  #
  # save with no container is a syntax error.
  #
  def test_save_with_no_param_is_a_syntax_error
    y = create_yaml_obj
    y.set_value( '/does/not/matter.yaml' )
    run_cmd 'tell y to save'

    assert_equal Gloo::Core::Error::SYNTAX, @engine.heap.error.kind
  end

  #
  # A container that doesn't exist is reported as not found.
  #
  def test_load_into_a_missing_container_is_an_error
    with_yaml_file( "title: T\n" ) do |y, _|
      run_cmd 'tell y to load (no_such_obj)'
      assert_equal Gloo::Core::NotFound.object( 'no_such_obj' ), @engine.heap.error.value
      assert_equal false, @engine.heap.it.value
    end
  end

  #
  # An empty path is an error, not an exception.
  #
  def test_load_with_an_empty_path_is_an_error
    create_yaml_obj
    create_container( 'data7', 'title' )
    run_cmd 'tell y to load (data7)'

    assert_includes @engine.heap.error.value, 'has no path'
    assert_equal false, @engine.heap.it.value
  end

  #
  # A successful load puts true in it.
  #
  def test_load_puts_true_in_it
    with_yaml_file( "title: T\n" ) do |y, _|
      create_container( 'data8', 'title' )
      run_cmd 'tell y to load (data8)'
      assert_equal true, @engine.heap.it.value
      refute @engine.error?
    end
  end

  #
  # A date loads as text instead of raising.
  #
  def test_load_a_date_as_text
    with_yaml_file( "date: 2026-10-01\n" ) do |y, _|
      data = create_container( 'data9', 'date' )
      run_cmd 'tell y to load (data9)'
      refute @engine.error?
      assert_equal '2026-10-01', data.find_child( 'date' ).value
    end
  end

  #
  # Invalid YAML is an error; it is false.
  #
  def test_load_invalid_yaml_is_an_error
    with_yaml_file( "title: [unclosed\n" ) do |y, _|
      create_container( 'data10', 'title' )
      run_cmd 'tell y to load (data10)'
      assert_includes @engine.heap.error.value, "Couldn't read the YAML"
      assert_equal false, @engine.heap.it.value
    end
  end

  #
  # A file that's a list, not key: value pairs, is an error.
  #
  def test_load_a_top_level_list_is_an_error
    with_yaml_file( "- a\n- b\n" ) do |y, _|
      create_container( 'data11', 'title' )
      run_cmd 'tell y to load (data11)'
      assert_includes @engine.heap.error.value, 'key: value pairs'
    end
  end

  #
  # A nested block is skipped with a warning; the child is unchanged.
  #
  def test_load_skips_a_nested_block_with_a_warning
    with_yaml_file( "server:\n  host: x\ntitle: T\n" ) do |y, _|
      data = create_container( 'data12', 'server', 'title' )
      data.find_child( 'server' ).set_value( 'unchanged' )
      @engine.log.reset_counts
      capture_io { run_cmd 'tell y to load (data12)' }

      assert_equal 'unchanged', data.find_child( 'server' ).value
      assert_equal 'T', data.find_child( 'title' ).value
      assert_equal 1, @engine.log.warning_count
      assert_equal true, @engine.heap.it.value
    end
  end

  #
  # save leaves a nested block or list in the file as it is.
  #
  def test_save_leaves_a_nested_block_and_a_list_untouched
    with_yaml_file( "server:\n  host: x\ntags:\n- a\n- b\ntitle: T\n" ) do |y, path|
      data = create_container( 'data13', 'server', 'tags', 'title' )
      data.find_child( 'title' ).set_value( 'Changed' )
      @engine.log.reset_counts
      capture_io { run_cmd 'tell y to save (data13)' }

      saved = YAML.load_file( path )
      assert_equal( { 'host' => 'x' }, saved[ 'server' ] )
      assert_equal %w[a b], saved[ 'tags' ]
      assert_equal 'Changed', saved[ 'title' ]
      assert_equal 2, @engine.log.warning_count
    end
  end

  #
  # save to a new file reports nothing.
  #
  def test_save_to_a_new_file_reports_no_error
    with_yaml_file( nil ) do |y, path|
      create_container( 'data14', 'title' )
      @engine.log.reset_counts
      capture_io { run_cmd 'tell y to save (data14)' }
      refute @engine.error?
      assert_equal 0, @engine.log.error_count
      assert File.exist?( path )
    end
  end

  #
  # save doesn't overwrite a file it couldn't read.
  #
  def test_save_does_not_overwrite_invalid_yaml
    with_yaml_file( "title: [unclosed\n" ) do |y, path|
      create_container( 'data15', 'title' )
      run_cmd 'tell y to save (data15)'
      assert_includes @engine.heap.error.value, "Couldn't read the YAML"
      assert_equal "title: [unclosed\n", File.read( path )
    end
  end

  #
  # A failed write is an error, not an exception.
  #
  def test_save_failure_is_an_error
    y = create_yaml_obj
    y.set_value( '/no/such/folder/data.yaml' )
    create_container( 'data16', 'title' )
    run_cmd 'tell y to save (data16)'
    assert_includes @engine.heap.error.value, 'Could not write'
  end

  def test_load_populates_container_children_from_the_file
    Dir.mktmpdir do |dir|
      path = File.join( dir, 'data.yaml' )
      File.write( path, "title: From File\ncount: '3'\n" )

      y = create_yaml_obj
      y.set_value( path )
      data = create_container( 'data', 'title', 'count' )

      i = @engine.parser.parse_immediate 'tell y to load (data)'
      i.run

      assert_equal 'From File', data.find_child( 'title' ).value
      assert_equal '3', data.find_child( 'count' ).value
    end
  end

  def test_load_leaves_children_untouched_when_their_key_is_absent
    Dir.mktmpdir do |dir|
      path = File.join( dir, 'data.yaml' )
      File.write( path, "title: From File\n" )

      y = create_yaml_obj
      y.set_value( path )
      data = create_container( 'data2', 'title', 'missing_key' )
      data.find_child( 'missing_key' ).set_value( 'unchanged' )

      i = @engine.parser.parse_immediate 'tell y to load (data2)'
      i.run

      assert_equal 'unchanged', data.find_child( 'missing_key' ).value
    end
  end

  #
  # A missing file is reported as not found; children are unchanged.
  #
  def test_load_from_a_missing_file_is_an_error
    path = '/tmp/does_not_exist_gloo_yaml_test.yaml'
    y = create_yaml_obj
    y.set_value( path )
    data = create_container( 'data3', 'title' )
    data.find_child( 'title' ).set_value( 'unchanged' )

    i = @engine.parser.parse_immediate 'tell y to load (data3)'
    i.run

    assert_equal 'unchanged', data.find_child( 'title' ).value
    assert_equal Gloo::Core::NotFound.file( path ), @engine.heap.error.value
    assert_equal false, @engine.heap.it.value
  end

  def test_save_writes_container_children_to_a_new_file
    Dir.mktmpdir do |dir|
      path = File.join( dir, 'new.yaml' )
      refute File.exist?( path )

      y = create_yaml_obj
      y.set_value( path )
      data = create_container( 'data4', 'title' )
      data.find_child( 'title' ).set_value( 'Saved Title' )

      i = @engine.parser.parse_immediate 'tell y to save (data4)'
      i.run

      assert File.exist?( path )
      assert_equal 'Saved Title', YAML.load_file( path )[ 'title' ]
    end
  end

  def test_save_preserves_existing_keys_not_represented_as_children
    Dir.mktmpdir do |dir|
      path = File.join( dir, 'existing.yaml' )
      File.write( path, "title: Original\nother_key: keep me\n" )

      y = create_yaml_obj
      y.set_value( path )
      data = create_container( 'data5', 'title' )
      data.find_child( 'title' ).set_value( 'Updated' )

      i = @engine.parser.parse_immediate 'tell y to save (data5)'
      i.run

      saved = YAML.load_file( path )
      assert_equal 'Updated', saved[ 'title' ]
      assert_equal 'keep me', saved[ 'other_key' ]
    end
  end

  def test_load_then_save_round_trips_a_value
    Dir.mktmpdir do |dir|
      path = File.join( dir, 'roundtrip.yaml' )
      File.write( path, "state: active\n" )

      y = create_yaml_obj
      y.set_value( path )
      data = create_container( 'data6', 'state' )

      i = @engine.parser.parse_immediate 'tell y to load (data6)'
      i.run
      assert_equal 'active', data.find_child( 'state' ).value

      i = @engine.parser.parse_immediate "put 'changed' into data6.state"
      i.run
      i = @engine.parser.parse_immediate 'tell y to save (data6)'
      i.run

      assert_equal 'changed', YAML.load_file( path )[ 'state' ]
    end
  end

end
