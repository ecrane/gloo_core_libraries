# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# msg_fetch is deliberately not exercised - it opens a real
# Net::IMAP connection and logs in. Only #process_message (pure data
# shaping from an already-fetched Mail::Message) is safe to test
# without a server.
#
require 'test_helper'

class EmailImapTest < BaseEngineTest

  def create_imap
    i = @engine.parser.parse_immediate 'create i as email_imap'
    i.run
    return @engine.heap.root.find_child( 'i' )
  end

  def test_the_typename
    assert_equal 'email_imap', EmailImap.typename
  end

  def test_the_short_typename_is_the_same_as_the_typename
    assert_equal EmailImap.typename, EmailImap.short_typename
  end

  def test_find_type
    assert @dic.find_obj( 'email_imap' )
  end

  def test_messages
    assert EmailImap.messages.include?( 'fetch' )
  end

  def test_adds_children_on_create
    o = EmailImap.new( @engine )
    assert o.add_children_on_create?
  end

  def test_that_children_are_added_on_create
    i = create_imap
    assert_equal 6, i.child_count
    assert_equal 'server', i.children[ 0 ].name
    assert_equal 'port', i.children[ 1 ].name
    assert_equal 'username', i.children[ 2 ].name
    assert_equal 'password', i.children[ 3 ].name
    assert_equal 'mailbox', i.children[ 4 ].name
    assert_equal 'messages', i.children[ 5 ].name
  end

  def test_process_message_adds_a_child_under_messages
    imap = create_imap
    mail = Mail.new do
      from    'sender@example.com'
      to      'recipient@example.com'
      subject 'A Subject'
      body    'The body text.'
    end

    imap.process_message( mail )

    msgs = imap.find_child( 'messages' )
    assert_equal 1, msgs.child_count

    entry = msgs.children.first
    assert_equal 'sender@example.com', entry.find_child( 'from' ).value
    assert_equal 'recipient@example.com', entry.find_child( 'to' ).value
    assert_equal 'A Subject', entry.find_child( 'subject' ).value
    assert_includes entry.find_child( 'body' ).value, 'The body text.'
  end

  def test_process_message_appends_rather_than_replacing
    imap = create_imap
    mail = Mail.new { from 'a@example.com'; to 'b@example.com'; subject 'One'; body 'One.' }

    imap.process_message( mail )
    imap.process_message( mail )

    msgs = imap.find_child( 'messages' )
    assert_equal 2, msgs.child_count
  end

end
