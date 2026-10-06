# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# The fetch message on email_imap. Nothing reaches a real server:
# Net::IMAP.new is replaced with a fake connection.
#
require 'test_helper'

#
# A stand-in for a Net::IMAP connection.
#
class FakeImap

  attr_reader :closed
  attr_accessor :login_error

  #
  # A connection holding the given raw (RFC822) messages, all unseen.
  #
  def initialize( raw_messages )
    @raw_messages = raw_messages
    @closed = false
  end

  #
  # Log in, or fail as the test asks.
  #
  def login( user, password )
    raise login_error if login_error
  end

  #
  # Select a mailbox.
  #
  def select( mailbox )
  end

  #
  # The ids of the unseen messages.
  #
  def search( keys )
    return ( 1..@raw_messages.size ).to_a
  end

  #
  # Fetch a message by id, shaped like Net::IMAP's FetchData.
  #
  def fetch( id, attr )
    data = Struct.new( :attr ).new( { attr => @raw_messages[ id - 1 ] } )
    return [ data ]
  end

  #
  # Log out.
  #
  def logout
  end

  #
  # Close the connection.
  #
  def disconnect
    @closed = true
  end

end

class FetchTest < BaseEngineTest

  #
  # Run a line of gloo.
  #
  def run_cmd( cmd )
    @engine.parser.parse_immediate( cmd ).run
  end

  #
  # An email_imap object named inbox.
  #
  def create_inbox
    run_cmd 'create inbox as email_imap'
    run_cmd "put 'imap.example.com' into inbox.server"
    return @engine.heap.root.find_child( 'inbox' )
  end

  #
  # Run the block with Net::IMAP.new giving the fake connection (or
  # raising, if fake is an exception).
  #
  def with_imap( fake )
    imap = Net::IMAP.singleton_class
    imap.alias_method( :real_new, :new )
    imap.define_method( :new ) do |*args|
      raise fake if fake.is_a?( Exception )
      fake
    end
    yield
  ensure
    imap.alias_method( :new, :real_new )
    imap.remove_method( :real_new )
  end

  #
  # A raw message with the given headers.
  #
  def raw( headers )
    return "#{headers}\r\n\r\nThe body.\r\n"
  end

  #
  # Unseen messages are added to messages, and it is true.
  #
  def test_fetch_adds_the_messages
    inbox = create_inbox
    fake = FakeImap.new( [ raw( "From: a@example.com\r\nTo: b@example.com\r\nSubject: One" ),
      raw( "From: c@example.com\r\nTo: b@example.com\r\nSubject: Two" ) ] )

    with_imap( fake ) { run_cmd 'tell inbox to fetch' }

    assert_equal true, @engine.heap.it.value
    msgs = inbox.find_child( 'messages' )
    assert_equal 2, msgs.child_count
    assert_equal 'Two', msgs.children.last.find_child( 'subject' ).value
    assert fake.closed
    refute @engine.error?
  end

  #
  # No new messages is not an error; it is true.
  #
  def test_fetch_with_no_new_messages
    inbox = create_inbox
    with_imap( FakeImap.new( [] ) ) { run_cmd 'tell inbox to fetch' }

    assert_equal true, @engine.heap.it.value
    assert_equal 0, inbox.find_child( 'messages' ).child_count
  end

  #
  # A message with no To: or From: is added with them empty.
  #
  def test_fetch_message_without_to_or_from
    inbox = create_inbox
    with_imap( FakeImap.new( [ raw( 'Subject: Bcc' ) ] ) ) { run_cmd 'tell inbox to fetch' }

    assert_equal true, @engine.heap.it.value
    entry = inbox.find_child( 'messages' ).children.first
    assert_equal '', entry.find_child( 'to' ).value
    assert_equal '', entry.find_child( 'from' ).value
  end

  #
  # Without a messages container, one is made.
  #
  def test_fetch_makes_the_messages_container
    inbox = create_inbox
    inbox.find_child( 'messages' ).delete_children
    inbox.remove_child( inbox.find_child( 'messages' ) )

    with_imap( FakeImap.new( [ raw( 'Subject: One' ) ] ) ) { run_cmd 'tell inbox to fetch' }

    assert_equal 1, inbox.find_child( 'messages' ).child_count
  end

  #
  # A server that can't be reached is a readable error; it is false.
  #
  def test_fetch_from_an_unreachable_server
    create_inbox
    with_imap( SocketError.new( 'getaddrinfo: nodename nor servname provided' ) ) do
      run_cmd 'tell inbox to fetch'
    end

    assert_equal false, @engine.heap.it.value
    assert_equal 'Could not fetch email from imap.example.com: ' \
      'getaddrinfo: nodename nor servname provided', @engine.heap.error.value
  end

  #
  # A refused login is a readable error, it is false, and the
  # connection is closed.
  #
  def test_fetch_with_a_refused_login
    create_inbox
    fake = FakeImap.new( [] )
    fake.login_error = RuntimeError.new( 'LOGIN failed' )

    with_imap( fake ) { run_cmd 'tell inbox to fetch' }

    assert_equal false, @engine.heap.it.value
    assert_equal 'Could not fetch email from imap.example.com: LOGIN failed',
      @engine.heap.error.value
    assert fake.closed
  end

end
