# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
require 'test_helper'

class CommandTest < BaseEngineTest

  def create_command
    i = @engine.parser.parse_immediate 'create c as command'
    i.run
    return @engine.heap.root.find_child( 'c' )
  end

  def test_the_typename
    assert_equal 'command', Command.typename
  end

  def test_the_short_typename
    assert_equal 'command', Command.short_typename
  end

  def test_find_type
    assert @dic.find_obj( 'command' )
  end

  def test_messages
    msgs = Command.messages
    assert msgs
    assert msgs.include?( 'register' )
    assert msgs.include?( 'unload' )
  end

  def test_adds_children_on_create
    o = Command.new( @engine )
    assert o.add_children_on_create?
  end

  def test_that_children_are_added_on_create
    c = create_command
    assert_equal 3, c.child_count
    assert_equal 'name', c.children[ 0 ].name
    assert_equal 'description', c.children[ 1 ].name
    assert_equal 'action', c.children[ 2 ].name
  end

  def test_description_defaults_to_empty_string_without_a_child
    c = Command.new( @engine )
    assert_equal '', c.description
  end

  def test_description_reads_the_description_child
    c = create_command
    i = @engine.parser.parse_immediate "put 'Do a thing' into c.description"
    i.run
    assert_equal 'Do a thing', c.description
  end

  def test_dynamic_is_false_without_a_dynamic_child
    c = create_command
    refute c.dynamic?
    assert_nil c.dynamic_key
  end

  def test_dynamic_is_true_with_a_dynamic_child
    c = create_command
    i = @engine.parser.parse_immediate "create c.dynamic as string : projects"
    i.run
    assert c.dynamic?
    assert_equal 'projects', c.dynamic_key
  end

  def test_options_key_and_options_default_empty
    c = create_command
    assert_nil c.options_key
    assert_empty c.options
  end

  def test_options_key_and_options_read_their_children
    c = create_command
    i = @engine.parser.parse_immediate "create c.options_key as string : colors"
    i.run
    assert_equal 'colors', c.options_key

    i = @engine.parser.parse_immediate 'create c.options as can'
    i.run
    i = @engine.parser.parse_immediate 'create c.options.r as string : red'
    i.run
    i = @engine.parser.parse_immediate 'create c.options.b as string : blue'
    i.run
    assert_equal [ 'red', 'blue' ], c.options
  end

  def test_nodes_is_nil_without_a_nodes_child
    c = create_command
    assert_nil c.nodes
  end

  def test_get_command_data_for_a_plain_command
    c = create_command
    i = @engine.parser.parse_immediate "put 'do it' into c.description"
    i.run

    data = c.get_command_data
    assert_equal c.name, data[ :name ]
    assert_equal 'do it', data[ :description ]
    assert_equal 'cmd_obj_action', data[ :method ]
    assert_equal c.pn, data[ :obj ]
    refute data.key?( :dynamic )
    refute data.key?( :children )
  end

  def test_get_command_data_for_a_dynamic_command
    c = create_command
    i = @engine.parser.parse_immediate "create c.dynamic as string : projects"
    i.run

    data = c.get_command_data
    assert data[ :dynamic ]
    assert_equal 'cmd_obj_action_with_context', data[ :method ]
    assert_equal 'projects', data[ :source ]
  end

  def test_get_command_data_for_a_command_with_child_nodes
    c = create_command
    i = @engine.parser.parse_immediate 'create c.nodes as can'
    i.run
    i = @engine.parser.parse_immediate 'create c.nodes.sub as command'
    i.run

    data = c.get_command_data
    assert data[ :children ]
    assert_equal 1, data[ :children ].count
    assert_equal 'sub', data[ :children ].first[ :name ]
  end

end
