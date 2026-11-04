# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# Starting and running the server: a server without config, a server
# that can't listen, starting twice. Thin's run is stubbed so nothing
# listens on a real port.
#
require 'test_helper'
require 'web_app_helper'

class SvrRunningTest < BaseEngineTest

  include WebAppHelper

  #
  # Load an app whose server has no config container.
  #
  def load_app_without_config
    load_gloo <<~GLOO
      app [can] :
        home [page] :
          content_type [string] : text
          body [string] : home
        svr [svr] :
          pages [can] :
            home [alias] : app.home
    GLOO
    return @engine.heap.root.find_child( 'app' ).find_child( 'svr' )
  end

  #
  # Run the block with Thin's run replaced by the given block.
  #
  def with_thin_run( fake )
    thin = Rack::Handler::Thin.singleton_class
    thin.alias_method( :real_run, :run )
    thin.define_method( :run ) { |*args, **opts, &blk| fake.call }
    yield
  ensure
    thin.alias_method( :run, :real_run )
    thin.remove_method( :real_run )
  end

  #
  # Make the server the running app with a web server whose thread is
  # this one, as if run_server failed in the server thread.
  #
  def running_server( svr )
    server = run_web_app( svr )
    svr.instance_variable_set( :@web_server, server )
    server.instance_variable_set( :@server_thread, Thread.current )
    return server
  end

  #
  # Run a line of gloo.
  #
  def run_cmd( cmd )
    @engine.parser.parse_immediate( cmd ).run
  end

  #
  # Without config, the settings are the defaults, not a failure.
  #
  def test_no_config_uses_the_defaults
    svr = load_app_without_config

    assert_nil svr.scheme_value
    refute svr.use_session?
    refute svr.session_cookie_secure
    assert_equal Objs::Svr::DEFAULT_COOKIE_PATH, svr.session_cookie_path
  end

  #
  # Without config, a request works.
  #
  def test_no_config_request_works
    server = run_web_app( load_app_without_config )

    code, _, body = get( server, '/home' )
    assert_equal 200, code
    assert_equal 'home', body
  end

  #
  # Starting a server doesn't make every thread's exception stop gloo.
  #
  def test_start_does_not_abort_on_any_thread_exception
    before = Thread.abort_on_exception
    with_thin_run( -> {} ) do
      server = WebSvr::Server.new( @engine, nil )
      server.start
      server.instance_variable_get( :@server_thread ).join
    end
    assert_equal before, Thread.abort_on_exception
  end

  #
  # A port in use is a readable error, and the app stops running.
  #
  def test_port_in_use_is_an_error
    server = running_server( load_app_without_config )

    with_thin_run( -> { raise 'no acceptor (port is in use or requires root privileges)' } ) do
      server.run_server
    end

    assert_equal "Could not start the web server on localhost:8080: " \
      'the port is in use or needs root privileges.', @engine.heap.error.value
    refute @engine.app_running?
  end

  #
  # Any other failure is handled as unexpected, and the app stops
  # running.
  #
  def test_other_failure_is_handled
    server = running_server( load_app_without_config )
    reported = []
    @engine.define_singleton_method( :handle_exception ) { |e| reported << e.message }

    with_thin_run( -> { raise 'boom' } ) do
      server.run_server
    end

    assert_equal [ 'boom' ], reported
    refute @engine.app_running?
  end

  #
  # Starting a server while one is running is an error.
  #
  def test_start_while_running_is_an_error
    svr = load_app_without_config
    run_web_app( svr )

    run_cmd 'tell app.svr to start'
    assert_equal Objs::Svr::SERVER_ALREADY_RUNNING, @engine.heap.error.value
    assert_same svr, @engine.running_app.obj
  end

  # ---------------------------------------------------------------------
  #    A web server is an app: it doesn't start in Script mode
  # ---------------------------------------------------------------------

  def test_start_in_script_mode_is_an_error_naming_the_app_folder
    pn = nil
    Dir.mktmpdir do |dir|
      pn = File.join( File.realpath( dir ), 'start.gloo' )
      File.write( pn, "start [can] :\n" )
      @engine.persist_man.load( pn )
    end
    load_app_without_config
    script_mode

    run_cmd 'tell app.svr to start'
    assert_equal format( Objs::Svr::NOT_IN_SCRIPT_MODE_ERR, File.dirname( pn ) ), @engine.heap.error.value
    refute @engine.app_running?, 'expected the server not to start'
  end

  def test_start_in_script_mode_with_no_file_uses_a_placeholder_folder
    load_app_without_config
    @engine.persist_man.maps.clear
    script_mode

    run_cmd 'tell app.svr to start'
    assert_equal format( Objs::Svr::NOT_IN_SCRIPT_MODE_ERR, '<folder>' ), @engine.heap.error.value
    refute @engine.app_running?
    refute @engine.heap.it.value
  end

  def test_start_outside_script_mode_starts_the_running_app
    svr = load_app_without_config
    started = []
    @engine.define_singleton_method( :start_running_app ) { |obj| started << obj }

    run_cmd 'tell app.svr to start'
    refute @engine.error?
    assert_equal [ svr ], started
  end

  private

  #
  # Make the engine report that it's running in Script mode.
  #
  def script_mode
    @engine.define_singleton_method( :mode ) { Gloo::App::Mode::SCRIPT }
  end

end
