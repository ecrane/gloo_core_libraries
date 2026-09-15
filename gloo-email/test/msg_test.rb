# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# Only covers construction and the in-memory Mail::Message it builds
# (get_mail). Nothing here connects to a server or sends anything -
# that's Smtp#send, deliberately not exercised (see smtp.rb - it
# calls Mail::Message#deliver!, real network I/O).
#
require 'test_helper'

class MsgTest < Minitest::Test

  def test_defaults_to_nil_fields
    m = Msg.new
    assert_nil m.to
    assert_nil m.from
    assert_nil m.subject
    assert_nil m.body
  end

  def test_holds_the_given_values
    m = Msg.new( 'to@example.com', 'from@example.com', 'Hello', 'Body text.' )

    assert_equal 'to@example.com', m.to
    assert_equal 'from@example.com', m.from
    assert_equal 'Hello', m.subject
    assert_equal 'Body text.', m.body
  end

  def test_to_s_includes_all_fields
    m = Msg.new( 'to@example.com', 'from@example.com', 'Hello', 'Body text.' )
    str = m.to_s

    assert_includes str, 'to@example.com'
    assert_includes str, 'from@example.com'
    assert_includes str, 'Hello'
    assert_includes str, 'Body text.'
  end

  def test_get_mail_builds_a_mail_message_with_the_same_fields
    m = Msg.new( 'to@example.com', 'from@example.com', 'Hello', 'Body text.' )
    mail = m.get_mail

    assert_kind_of Mail::Message, mail
    assert_equal [ 'to@example.com' ], mail.to
    assert_equal [ 'from@example.com' ], mail.from
    assert_equal 'Hello', mail.subject
    assert_equal 'Body text.', mail.body.to_s
  end

end
