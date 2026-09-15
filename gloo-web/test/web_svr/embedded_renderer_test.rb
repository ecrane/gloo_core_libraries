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

end
