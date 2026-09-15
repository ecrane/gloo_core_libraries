# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# Only covers the parts reachable without a live request: session id
# generation and the config-delegation helpers. set_session_data_for_request
# and add_session_for_response need a real Rack env/headers hash and
# encryption key/iv aliases - out of scope here, see the story notes.
#
require 'test_helper'

class SessionTest < BaseEngineTest

  def create_svr
    o = @engine.parser.parse_immediate 'create s as svr'
    o.run
    return @engine.heap.root.children.first
  end

  def test_get_session_id_generates_and_caches_one
    session = WebSvr::Session.new( @engine, create_svr )

    id = session.get_session_id
    refute_nil id
    assert_equal id, session.get_session_id
  end

  def test_clear_session_data_forces_a_nil_id_once
    session = WebSvr::Session.new( @engine, create_svr )
    session.get_session_id

    session.clear_session_data
    assert_nil session.get_session_id

    # after the one-time nil, a fresh id is generated again
    refute_nil session.get_session_id
  end

  def test_add_session_to_response_sets_the_include_flag
    session = WebSvr::Session.new( @engine, create_svr )
    refute session.instance_variable_get( :@include_in_response )

    session.add_session_to_response
    assert session.instance_variable_get( :@include_in_response )
  end

  def test_clear_session_data_also_sets_the_include_flag
    session = WebSvr::Session.new( @engine, create_svr )
    session.clear_session_data
    assert session.instance_variable_get( :@include_in_response )
  end

  def test_delegates_cookie_settings_to_the_server_obj
    svr = create_svr
    session = WebSvr::Session.new( @engine, svr )

    assert_equal svr.session_cookie_path, session.cookie_path
    # session_cookie_expires computes '1.week.from_now' fresh on each
    # call, so two separate calls are microseconds apart - compare
    # with a tolerance instead of exact equality.
    assert_in_delta svr.session_cookie_expires, session.cookie_expires, 1
    assert_equal svr.session_cookie_secure, session.secure_cookie?
  end

  def test_session_name_defaults_to_nil_without_config
    svr = create_svr
    session = WebSvr::Session.new( @engine, svr )
    assert_nil session.session_name
  end

  def test_session_name_reads_the_configured_value
    svr = create_svr
    i = @engine.parser.parse_immediate "create s.config.session_name as string : _my_app_session"
    i.run

    session = WebSvr::Session.new( @engine, svr )
    assert_equal '_my_app_session', session.session_name
  end

end
