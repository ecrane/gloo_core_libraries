require 'test_helper'

class EmbeddedRendererTest < BaseEngineTest

  def test_creation
    svr = Objs::Svr.new @engine

    o = WebSvr::EmbeddedRenderer.new @engine, svr
    assert o
    assert o.engine
    assert o.log
    assert_same o.web_svr_obj, svr
  end

  #
  # A renderer for a new server object.
  #
  def renderer
    return WebSvr::EmbeddedRenderer.new( @engine, Objs::Svr.new( @engine ) )
  end

  #
  # Run a line of gloo.
  #
  def run_cmd( cmd )
    @engine.parser.parse_immediate( cmd ).run
  end

  #
  # A helper function is called and its result rendered.
  #
  def test_calls_a_helper_function
    run_cmd 'create helper as can'
    run_cmd 'create helper.greet as function'
    run_cmd 'create helper.greet.on_invoke as script'
    run_cmd 'create helper.greet.result as string'
    run_cmd "put 'hi' into helper.greet.result"

    assert_equal 'say hi', renderer.render( 'say <%= greet %>', {} )
    refute @engine.error?
  end

  #
  # A helper that doesn't exist is an error, and renders as blank.
  #
  def test_missing_helper_is_an_error
    assert_equal 'say ', renderer.render( 'say <%= greet %>', {} )
    assert_equal "Helper function 'greet' was not found; add it as helper.greet.",
      @engine.heap.error.value
  end

  #
  # A helper that isn't a function is an error, and renders as blank.
  #
  def test_helper_that_is_not_a_function_is_an_error
    run_cmd 'create helper as can'
    run_cmd 'create helper.greet as string'

    assert_equal 'say ', renderer.render( 'say <%= greet %>', {} )
    assert_equal "'helper.greet' is not a function.", @engine.heap.error.value
  end

end
