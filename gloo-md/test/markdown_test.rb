require 'test_helper'

class MarkdownTest < BaseEngineTest

  def test_the_typename
    assert_equal 'markdown', Md.typename
  end

  def test_the_short_typename
    assert_equal 'md', Md.short_typename
  end

  def test_doc_data
    data = Md.doc_data
    assert_equal Md.typename, data[ :name ]
    assert_equal Md.short_typename, data[ :shortcut ]
  end

  def test_find_type
    assert @dic.find_obj( 'markdown' )
    assert @dic.find_obj( 'MD' )
  end

  def test_messages
    msgs = Md.messages
    assert msgs
    assert msgs.include?( 'show' )
  end

  def test_adds_children_on_create
    o = Md.new @engine
    refute o.add_children_on_create?
  end

  #
  # Create a markdown object holding the given text.
  #
  def create_md( text )
    @engine.parser.parse_immediate( 'create m as markdown' ).run
    m = @engine.heap.root.find_child( 'm' )
    m.set_value text
    return m
  end

  #
  # With no destination, render puts the HTML in it.
  #
  def test_render_without_a_destination_puts_the_html_in_it
    create_md '# Hello'
    @engine.parser.parse_immediate( 'tell m to render' ).run

    assert_includes @engine.heap.it.value, '<h1>Hello</h1>'
  end

  #
  # With a destination, render puts the HTML there and true in it.
  #
  def test_render_with_a_destination_puts_true_in_it
    create_md '# Hello'
    @engine.parser.parse_immediate( 'create h as string' ).run
    @engine.parser.parse_immediate( 'tell m to render (h)' ).run

    assert_equal true, @engine.heap.it.value
    assert_includes @engine.heap.root.find_child( 'h' ).value, '<h1>Hello</h1>'
  end

  #
  # A destination that doesn't exist is an error, and it is false.
  #
  def test_render_to_a_missing_destination_is_an_error
    create_md '# Hello'
    @engine.parser.parse_immediate( 'tell m to render (no_such_obj)' ).run

    assert_equal Gloo::Core::NotFound.object( 'no_such_obj' ), @engine.heap.error.value
    assert_equal false, @engine.heap.it.value
  end

end
