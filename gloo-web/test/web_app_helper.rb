# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# Helpers for tests that need a running web app: load an app from gloo
# text, set up its server object the way Objs::Svr#start does (but
# without starting a listening server), and send it requests through
# WebSvr::Server#call.
#
require 'tmpdir'
require 'rack/mock'

module WebAppHelper

  #
  # Load the given gloo text, as if from a file.
  #
  def load_gloo( text )
    Dir.mktmpdir do |dir|
      pn = File.join( dir, 'app.gloo' )
      File.write( pn, text )
      @engine.parser.parse_immediate( "load #{pn}" ).run
    end
  end

  #
  # Make the given server object the running app, set up as
  # Objs::Svr#start does, but without listening on a port.
  # Returns the server that handles requests.
  #
  def run_web_app( svr )
    @engine.instance_variable_set( :@running_app,
      Gloo::App::RunningApp.new( svr, @engine ) )

    svr.router = Routing::Router.new( @engine, svr )
    svr.asset = WebSvr::Asset.new( @engine, svr )
    svr.embedded_renderer = WebSvr::EmbeddedRenderer.new( @engine, svr )
    svr.session = WebSvr::Session.new( @engine, svr )

    handler = WebSvr::Handler.new( @engine, svr )
    return WebSvr::Server.new( @engine, handler )
  end

  #
  # Send a GET request for the path; returns the Rack result:
  # [ code, headers, body ].
  #
  def get( server, path )
    return server.call( Rack::MockRequest.env_for( path ) )
  end

  #
  # The running app was never started, so it must not be stopped:
  # drop it before the engine shuts down.
  #
  def teardown
    @engine&.instance_variable_set( :@running_app, nil )
    super
  end

end
