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

  def test_load_with_no_params_does_nothing
    y = create_yaml_obj
    y.set_value( '/does/not/matter.yaml' )
    y.instance_variable_set( :@params, nil )

    y.msg_load # should not raise
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

  def test_load_from_a_missing_file_logs_and_leaves_children_untouched
    y = create_yaml_obj
    y.set_value( '/tmp/does_not_exist_gloo_yaml_test.yaml' )
    data = create_container( 'data3', 'title' )
    data.find_child( 'title' ).set_value( 'unchanged' )

    i = @engine.parser.parse_immediate 'tell y to load (data3)'
    i.run

    assert_equal 'unchanged', data.find_child( 'title' ).value
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
