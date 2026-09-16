require 'test_helper'

class ColorizeTest < BaseEngineTest

  def test_the_typename
    assert_equal 'colorize', CliColorize.typename
  end

  def test_the_short_typename
    assert_equal 'color', CliColorize.short_typename
  end

  def test_doc_data
    data = CliColorize.doc_data
    assert_equal CliColorize.typename, data[ :name ]
    assert_equal CliColorize.short_typename, data[ :shortcut ]
  end

  def test_find_type
    assert @dic.find_obj( 'colorize' )
    assert @dic.find_obj( 'color' )
  end

  def test_messages
    msgs = CliColorize.messages
    assert msgs
    assert msgs.include?( 'run' )
    assert msgs.include?( 'unload' )
  end

  def test_adds_children_on_create
    o = CliColorize.new( @engine )
    assert o.add_children_on_create?
  end

end
