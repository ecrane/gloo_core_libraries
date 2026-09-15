require 'test_helper'

class ConfigTest < BaseEngineTest

  def test_creation
    c = WebSvr::Config.new
    assert c
    assert_equal WebSvr::Config::HTTP, c.scheme
    assert_equal WebSvr::Config::LOCALHOST, c.host
    assert_equal WebSvr::Config::PORT_DEFAULT, c.port
  end

  def test_base_url
    c = WebSvr::Config.new
    assert c
    assert_equal 'http://localhost:8080', c.base_url
  end

end
