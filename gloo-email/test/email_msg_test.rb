# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# msg_send is deliberately not exercised - it resolves an
# email_smtp object and calls Smtp#send, real network I/O.
#
require 'test_helper'

class EmailMsgTest < BaseEngineTest

  def create_msg
    i = @engine.parser.parse_immediate 'create m as email'
    i.run
    return @engine.heap.root.find_child( 'm' )
  end

  def test_the_typename
    assert_equal 'email', EmailMsg.typename
  end

  def test_the_short_typename_is_the_same_as_the_typename
    assert_equal EmailMsg.typename, EmailMsg.short_typename
  end

  def test_doc_data
    data = EmailMsg.doc_data
    assert_equal EmailMsg.typename, data[ :name ]
    assert_equal EmailMsg.short_typename, data[ :shortcut ]
  end

  def test_find_type
    assert @dic.find_obj( 'email' )
  end

  def test_messages
    assert EmailMsg.messages.include?( 'send' )
  end

  def test_adds_children_on_create
    o = EmailMsg.new( @engine )
    assert o.add_children_on_create?
  end

  def test_that_children_are_added_on_create
    m = create_msg
    assert_equal 4, m.child_count
    assert_equal 'to', m.children[ 0 ].name
    assert_equal 'from', m.children[ 1 ].name
    assert_equal 'subject', m.children[ 2 ].name
    assert_equal 'body', m.children[ 3 ].name
  end

  def test_accessors_read_their_children
    m = create_msg
    i = @engine.parser.parse_immediate "put 'to@example.com' into m.to"
    i.run
    i = @engine.parser.parse_immediate "put 'from@example.com' into m.from"
    i.run
    i = @engine.parser.parse_immediate "put 'Hello' into m.subject"
    i.run
    i = @engine.parser.parse_immediate "put 'Body text.' into m.body"
    i.run

    assert_equal 'to@example.com', m.to
    assert_equal 'from@example.com', m.from
    assert_equal 'Hello', m.subject
    assert_equal 'Body text.', m.body
  end

  def test_get_msg_builds_a_msg_from_the_children
    m = create_msg
    i = @engine.parser.parse_immediate "put 'to@example.com' into m.to"
    i.run
    i = @engine.parser.parse_immediate "put 'Hello' into m.subject"
    i.run

    msg = m.get_msg
    assert_kind_of Msg, msg
    assert_equal 'to@example.com', msg.to
    assert_equal 'Hello', msg.subject
  end

end
