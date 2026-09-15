require 'test_helper'

class MarkdownTest < BaseEngineTest

  def test_the_typename
    assert_equal 'markdown', Md.typename
  end

  def test_the_short_typename
    assert_equal 'md', Md.short_typename
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

end
