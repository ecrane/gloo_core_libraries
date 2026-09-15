# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# Deliberately does NOT call WebSvr::Server#start (or Objs::Svr#start/
# #msg_start, or @engine.start_running_app) anywhere in this file -
# #start spawns a thread that binds a real port via Thin. Only the
# constructor and #call's request-building are safe to exercise
# without an actual listening server.
#
require 'test_helper'

class ServerTest < BaseEngineTest

  def build_handler
    o = @engine.parser.parse_immediate 'create s as svr'
    o.run
    obj = @engine.heap.root.children.first
    return WebSvr::Handler.new( @engine, obj )
  end

  def test_creation_does_not_start_listening
    handler = build_handler
    server = WebSvr::Server.new( @engine, handler )

    refute server.instance_variable_get( :@server_thread )
  end

  def test_defaults_to_a_new_config_when_none_given
    handler = build_handler
    server = WebSvr::Server.new( @engine, handler )

    config = server.instance_variable_get( :@config )
    assert_kind_of WebSvr::Config, config
    assert_equal WebSvr::Config::PORT_DEFAULT, config.port
  end

  def test_uses_the_given_config_instead_of_a_default
    handler = build_handler
    config = WebSvr::Config.new( 'http', 'example.com', '9999' )
    server = WebSvr::Server.new( @engine, handler, config )

    assert_same config, server.instance_variable_get( :@config )
  end

  def test_holds_the_given_ssl_config
    handler = build_handler
    ssl_config = { private_key_file: 'key.pem', cert_chain_file: 'cert.pem' }
    server = WebSvr::Server.new( @engine, handler, nil, ssl_config )

    assert_equal ssl_config, server.instance_variable_get( :@ssl_config )
  end

end
