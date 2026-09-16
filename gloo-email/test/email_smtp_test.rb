# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# msg_send is deliberately not exercised - it calls Smtp#send, which
# calls Mail::Message#deliver!, real network I/O to an SMTP server.
#
require 'test_helper'

class EmailSmtpTest < BaseEngineTest

  def create_smtp
    i = @engine.parser.parse_immediate 'create s as email_smtp'
    i.run
    return @engine.heap.root.find_child( 's' )
  end

  def test_the_typename
    assert_equal 'email_smtp', EmailSmtp.typename
  end

  def test_the_short_typename_is_the_same_as_the_typename
    assert_equal EmailSmtp.typename, EmailSmtp.short_typename
  end

  def test_doc_data
    data = EmailSmtp.doc_data
    assert_equal EmailSmtp.typename, data[ :name ]
    assert_equal EmailSmtp.short_typename, data[ :shortcut ]
  end

  def test_find_type
    assert @dic.find_obj( 'email_smtp' )
  end

  def test_messages
    assert EmailSmtp.messages.include?( 'send' )
  end

  def test_adds_children_on_create
    o = EmailSmtp.new( @engine )
    assert o.add_children_on_create?
  end

  def test_that_children_are_added_on_create
    s = create_smtp
    assert_equal 4, s.child_count
    assert_equal 'server', s.children[ 0 ].name
    assert_equal 'port', s.children[ 1 ].name
    assert_equal 'username', s.children[ 2 ].name
    assert_equal 'password', s.children[ 3 ].name
  end

  def test_accessors_read_their_children
    s = create_smtp
    i = @engine.parser.parse_immediate "put 'smtp.example.com' into s.server"
    i.run
    i = @engine.parser.parse_immediate "put '587' into s.port"
    i.run
    i = @engine.parser.parse_immediate "put 'me@example.com' into s.username"
    i.run
    i = @engine.parser.parse_immediate "put 'secret' into s.password"
    i.run

    assert_equal 'smtp.example.com', s.server
    assert_equal '587', s.port
    assert_equal 'me@example.com', s.username
    assert_equal 'secret', s.password
  end

  def test_get_config_builds_a_config_from_the_children
    s = create_smtp
    i = @engine.parser.parse_immediate "put 'smtp.example.com' into s.server"
    i.run
    i = @engine.parser.parse_immediate "put 'me@example.com' into s.username"
    i.run

    config = s.get_config
    assert_kind_of Config, config
    assert_equal 'smtp.example.com', config.host
    assert_equal 'me@example.com', config.username
  end

end
