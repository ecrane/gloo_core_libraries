# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# What a request returns when something goes wrong: a missing route,
# a bug in gloo-web's own code, a page that doesn't render.
#
require 'test_helper'
require 'web_app_helper'

class RequestErrorsTest < BaseEngineTest

  include WebAppHelper

  #
  # An app with a home page, and the given lines added to the server.
  #
  def app_with( svr_lines = '' )
    load_gloo <<~GLOO
      app [can] :
        home [page] :
          content_type [string] : text
          body [string] : home
        err [page] :
          content_type [string] : text
          body [string] : something went wrong
        missing [page] :
          content_type [string] : text
          body [string] : no such page
        svr [svr] :
          config [can] :
          #{svr_lines}
          pages [can] :
            home [alias] : app.home
    GLOO
    return run_web_app( @engine.heap.root.find_child( 'app' ).find_child( 'svr' ) )
  end

  #
  # A route that works is a 200 with the page.
  #
  def test_a_route_that_works
    code, _, body = get( app_with, '/home' )
    assert_equal 200, code
    assert_equal 'home', body
  end

  #
  # A missing route, with no not_found page, is a plain 404.
  #
  def test_missing_route_is_a_404
    code, _, body = get( app_with, '/nope' )
    assert_equal 404, code
    assert_equal WebSvr::Handler::NOT_FOUND_MSG, body
  end

  #
  # A missing route sends the not_found page, as a 404.
  #
  def test_missing_route_sends_the_not_found_page
    code, _, body = get( app_with( 'not_found [alias] : app.missing' ), '/nope' )
    assert_equal 404, code
    assert_equal 'no such page', body
  end

  #
  # A Ruby exception in gloo-web's own code is handled and sends a
  # plain 500, instead of escaping into the web server.
  #
  def test_an_exception_sends_a_500
    server = app_with
    handler = server.instance_variable_get( :@handler )
    handler.define_singleton_method( :handle ) { |_| raise 'boom' }
    reported = []
    @engine.define_singleton_method( :handle_exception ) { |e| reported << e.message }

    code, _, body = get( server, '/home' )
    assert_equal 500, code
    assert_equal WebSvr::Handler::SERVER_ERR_MSG, body
    assert_equal [ 'boom' ], reported
  end

  #
  # An exception sends the app's error page, as a 500.
  #
  def test_an_exception_sends_the_error_page
    server = app_with( 'error [alias] : app.err' )
    handler = server.instance_variable_get( :@handler )
    handler.define_singleton_method( :handle ) { |_| raise 'boom' }

    code, _, body = get( server, '/home' )
    assert_equal 500, code
    assert_equal 'something went wrong', body
  end

  #
  # If the error page fails too, a plain 500 is sent.
  #
  def test_a_failing_error_page_sends_a_plain_500
    server = app_with( 'error [alias] : app.err' )
    handler = server.instance_variable_get( :@handler )
    handler.define_singleton_method( :handle ) { |_| raise 'boom' }
    handler.define_singleton_method( :server_error_result ) { raise 'again' }

    code, _, body = get( server, '/home' )
    assert_equal 500, code
    assert_equal WebSvr::Handler::SERVER_ERR_MSG, body
  end

  #
  # A page that doesn't render (an unknown content type) sends a 500.
  #
  def test_a_page_that_does_not_render_sends_a_500
    server = app_with
    @engine.heap.root.find_child( 'app' ).find_child( 'home' )
      .find_child( 'content_type' ).set_value( 'pdf' )

    code, _, _ = get( server, '/home' )
    assert_equal 500, code
  end

  #
  # The error page is sent as a 500 even if its own return code says
  # otherwise.
  #
  def test_error_page_status_is_set_by_the_server
    server = app_with( 'error [alias] : app.err' )
    err = @engine.heap.root.find_child( 'app' ).find_child( 'err' )
    @engine.factory.create_int( 'return_code', 200, err )
    handler = server.instance_variable_get( :@handler )
    handler.define_singleton_method( :handle ) { |_| raise 'boom' }

    code, _, _ = get( server, '/home' )
    assert_equal 500, code
  end

end
