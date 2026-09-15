
require 'test_helper'

class PartialTest < BaseEngineTest

  def test_the_typename
    assert_equal 'partial', Objs::Partial.typename
  end

  def test_the_short_typename
    assert_equal 'part', Objs::Partial.short_typename
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
