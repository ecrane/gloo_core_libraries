require 'test_helper'

class WebMethodTest < BaseEngineTest

  def test_is_get_check
    assert WebSvr::WebMethod.is_get?( 'get' )
    assert WebSvr::WebMethod.is_get?( 'GET' )
    assert WebSvr::WebMethod.is_get?( 'Get' )

    refute WebSvr::WebMethod.is_get?( 'git' )
    refute WebSvr::WebMethod.is_get?( 'post' )
    refute WebSvr::WebMethod.is_get?( 'delete' )
    refute WebSvr::WebMethod.is_get?( 'put' )
  end

  def test_is_post_check
    assert WebSvr::WebMethod.is_post?( 'post' )
    assert WebSvr::WebMethod.is_post?( 'POST' )
    assert WebSvr::WebMethod.is_post?( 'poST' )

    refute WebSvr::WebMethod.is_post?( 'po' )
    refute WebSvr::WebMethod.is_post?( 'get' )
    refute WebSvr::WebMethod.is_post?( 'delete' )
    refute WebSvr::WebMethod.is_post?( 'put' )
  end

  def test_is_put_check
    assert WebSvr::WebMethod.is_put?( 'put' )
    assert WebSvr::WebMethod.is_put?( 'PUT' )
    assert WebSvr::WebMethod.is_put?( 'Put' )

    refute WebSvr::WebMethod.is_put?( 'post' )
    refute WebSvr::WebMethod.is_put?( 'get' )
    refute WebSvr::WebMethod.is_put?( 'delete' )
    refute WebSvr::WebMethod.is_put?( 'putter' )
  end

  def test_is_patch_check
    assert WebSvr::WebMethod.is_patch?( 'patch' )
    assert WebSvr::WebMethod.is_patch?( 'PATCH' )
    assert WebSvr::WebMethod.is_patch?( 'Patch' )

    refute WebSvr::WebMethod.is_patch?( 'pat' )
    refute WebSvr::WebMethod.is_patch?( 'get' )
    refute WebSvr::WebMethod.is_patch?( 'delete' )
    refute WebSvr::WebMethod.is_patch?( 'put' )
  end

  def test_is_delete_check
    assert WebSvr::WebMethod.is_delete?( 'delete' )
    assert WebSvr::WebMethod.is_delete?( 'DELETE' )
    assert WebSvr::WebMethod.is_delete?( 'Delete' )

    refute WebSvr::WebMethod.is_delete?( 'del' )
    refute WebSvr::WebMethod.is_delete?( 'get' )
    refute WebSvr::WebMethod.is_delete?( 'post' )
    refute WebSvr::WebMethod.is_delete?( 'put' )
  end

end
