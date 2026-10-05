# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# The render message on page and partial: the content goes in it, and
# it is false when it can't render.
#
require 'test_helper'
require 'web_app_helper'

class RenderMessageTest < BaseEngineTest

  include WebAppHelper

  #
  # Load an app with a text page, an html page and a partial.
  #
  def load_app
    load_gloo <<~GLOO
      app [can] :
        txt [page] :
          content_type [string] : text
          body [string] : hello
        html [page] :
          body [can] :
            p [e] : hi
        part [partial] :
          content [string] : <b>bold</b>
        svr [svr] :
          config [can] :
          pages [can] :
    GLOO
  end

  #
  # Load the app and make it the running app.
  #
  def start_app
    load_app
    run_web_app( @engine.heap.root.find_child( 'app' ).find_child( 'svr' ) )
  end

  #
  # Run a line of gloo.
  #
  def run_cmd( cmd )
    @engine.parser.parse_immediate( cmd ).run
  end

  #
  # A page renders its content into it, as text.
  #
  def test_page_render_puts_the_content_in_it
    start_app
    run_cmd 'tell app.txt to render'
    assert_equal 'hello', @engine.heap.it.value
    refute @engine.error?
  end

  #
  # An html page renders its html into it.
  #
  def test_html_page_render_puts_the_html_in_it
    start_app
    run_cmd 'tell app.html to render'
    assert_includes @engine.heap.it.value, 'hi'
    assert_includes @engine.heap.it.value, '<html>'
  end

  #
  # A page with an unknown content type is an error; it is false.
  #
  def test_page_render_unknown_content_type
    start_app
    run_cmd "put 'pdf' into app.txt.content_type"
    run_cmd 'tell app.txt to render'
    assert_equal false, @engine.heap.it.value
    assert_equal 'Unknown content type: pdf', @engine.heap.error.value
  end

  #
  # A page can't render outside a web app; it is false.
  #
  def test_page_render_outside_a_web_app
    load_app
    run_cmd 'tell app.txt to render'
    assert_equal false, @engine.heap.it.value
    assert_equal "page 'txt' can only render inside a web app (gloo-web).",
      @engine.heap.error.value
  end

  #
  # A partial renders its html into it.
  #
  def test_partial_render_puts_the_html_in_it
    start_app
    run_cmd 'tell app.part to render'
    assert_equal '<b>bold</b>', @engine.heap.it.value
  end

  #
  # A partial can't render outside a web app; it is false.
  #
  def test_partial_render_outside_a_web_app
    load_app
    run_cmd 'tell app.part to render'
    assert_equal false, @engine.heap.it.value
    assert_equal "partial 'part' can only render inside a web app (gloo-web).",
      @engine.heap.error.value
  end

end
