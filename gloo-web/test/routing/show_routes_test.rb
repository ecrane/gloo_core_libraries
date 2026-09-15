require 'test_helper'

class ShowRoutesTest < BaseEngineTest

  def test_creation
    o = Routing::ShowRoutes.new( @engine )
    assert o
  end

  def test_getting_headers
    o = Routing::ShowRoutes.new( @engine )
    assert o.headers
    assert_equal 4, o.headers.count
  end

end
