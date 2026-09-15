require 'test_helper'

class ResourceRouterTest < BaseEngineTest

  def test_is_implicit_create_check
    refute Routing::ResourceRouter.is_implicit_create?( 'get', 'create' )
    refute Routing::ResourceRouter.is_implicit_create?( 'put', 'create' )
    refute Routing::ResourceRouter.is_implicit_create?( 'delete', 'other' )

    refute Routing::ResourceRouter.is_implicit_create?( 'post', 'create' )

    assert Routing::ResourceRouter.is_implicit_create?( 'post', 'messages' )
    assert Routing::ResourceRouter.is_implicit_create?( 'post', 'users' )
  end

end
