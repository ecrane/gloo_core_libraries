# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# The send message on email_smtp and email. Nothing reaches a real
# server: Smtp#configure is replaced so Mail uses its test delivery
# (or a delivery that fails).
#
require 'test_helper'

#
# A Mail delivery method that always fails, as a refused login would.
#
class FailingDelivery

  #
  # Mail passes the delivery settings.
  #
  def initialize( settings )
  end

  #
  # Fail to deliver.
  #
  def deliver!( mail )
    raise Net::SMTPAuthenticationError.new( '535 Authentication failed' )
  end

end

#
# Replaces Smtp#configure with the delivery method the test chose.
#
module TestDelivery

  class << self
    attr_accessor :method
  end

  #
  # Use the test's delivery method instead of SMTP.
  #
  def configure
    method = TestDelivery.method
    Mail.defaults { delivery_method method }
  end

end
Smtp.prepend( TestDelivery )

class SendTest < BaseEngineTest

  #
  # Deliver with Mail's test delivery, and start with no deliveries.
  #
  def setup
    super
    TestDelivery.method = :test
    Mail::TestMailer.deliveries.clear
    run_cmd 'create mail as can'
    run_cmd 'create mail.smtp as email_smtp'
    run_cmd 'create mail.msg as email'
    run_cmd "put 'someone@example.com' into mail.msg.to"
    run_cmd "put 'me@example.com' into mail.msg.from"
    run_cmd "put 'Hello' into mail.msg.subject"
    run_cmd 'create mail.text as string'
  end

  #
  # Run a line of gloo.
  #
  def run_cmd( cmd )
    @engine.parser.parse_immediate( cmd ).run
  end

  #
  # The messages delivered so far.
  #
  def deliveries
    return Mail::TestMailer.deliveries
  end

  #
  # smtp send (msg) sends it, and it is true.
  #
  def test_smtp_send_sends_the_message
    run_cmd 'tell mail.smtp to send (mail.msg)'

    assert_equal true, @engine.heap.it.value
    assert_equal 1, deliveries.size
    assert_equal 'Hello', deliveries.first.subject
    refute @engine.error?
  end

  #
  # email send (smtp) sends it, and it is true.
  #
  def test_email_send_sends_the_message
    run_cmd 'tell mail.msg to send (mail.smtp)'

    assert_equal true, @engine.heap.it.value
    assert_equal [ 'someone@example.com' ], deliveries.first.to
  end

  #
  # A failed delivery is a readable error, and it is false.
  #
  def test_failed_delivery_is_an_error
    TestDelivery.method = FailingDelivery
    run_cmd 'tell mail.smtp to send (mail.msg)'

    assert_equal false, @engine.heap.it.value
    assert_equal 'Could not send email: 535 Authentication failed',
      @engine.heap.error.value
  end

  #
  # Without a parameter, it is a syntax error, and it is false.
  #
  def test_smtp_send_without_a_message
    run_cmd 'tell mail.smtp to send'

    assert_equal false, @engine.heap.it.value
    assert_equal 'Missing the email message! eg. tell smtp to send (my.email)',
      @engine.heap.error.value
    assert_equal Gloo::Core::Error::SYNTAX, @engine.heap.error.kind
    assert_empty deliveries
  end

  #
  # Without a parameter, it is a syntax error, and it is false.
  #
  def test_email_send_without_an_smtp
    run_cmd 'tell mail.msg to send'

    assert_equal false, @engine.heap.it.value
    assert_equal 'Missing the email_smtp object! eg. tell msg to send (my.smtp)',
      @engine.heap.error.value
  end

  #
  # A path to nothing is not found, and it is false.
  #
  def test_send_to_nothing
    run_cmd 'tell mail.smtp to send (mail.nope)'

    assert_equal false, @engine.heap.it.value
    assert_equal Gloo::Core::NotFound.object( 'mail.nope' ), @engine.heap.error.value
    assert_empty deliveries
  end

  #
  # A path to the wrong kind of object is an error, and it is false.
  #
  def test_smtp_send_with_something_else
    run_cmd 'tell mail.smtp to send (mail.text)'

    assert_equal false, @engine.heap.it.value
    assert_equal "'mail.text' is not an email message.", @engine.heap.error.value
  end

  #
  # A path to the wrong kind of object is an error, and it is false.
  #
  def test_email_send_with_something_else
    run_cmd 'tell mail.msg to send (mail.text)'

    assert_equal false, @engine.heap.it.value
    assert_equal "'mail.text' is not an email_smtp object.", @engine.heap.error.value
  end

end
