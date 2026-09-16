
require 'test_helper'

class PartialTest < BaseEngineTest

  def test_the_typename
    assert_equal 'partial', Objs::Partial.typename
  end

  def test_the_short_typename
    assert_equal 'part', Objs::Partial.short_typename
  end

  def test_doc_data
    data = Objs::Partial.doc_data
    assert_equal Objs::Partial.typename, data[ :name ]
    assert_equal Objs::Partial.short_typename, data[ :shortcut ]
  end

  def test_find_type
    assert @dic.find_obj( 'partial' )
    assert @dic.find_obj( 'part' )
  end

  def test_messages
    msgs = Objs::Partial.messages
    assert msgs
    assert msgs.include?( 'render' )
  end

  def test_adds_children_on_create
    o = Objs::Partial.new @engine
    assert o.add_children_on_create?
  end

end
