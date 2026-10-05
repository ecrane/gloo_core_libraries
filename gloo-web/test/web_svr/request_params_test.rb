require 'test_helper'

class RequestParamsTest < BaseEngineTest

  def test_creation
    o = WebSvr::RequestParams.new( nil, nil )
    assert o
  end

  #
  # An upload body that can't be read is an error, with no backtrace.
  #
  def test_unreadable_upload_is_an_error
    params = WebSvr::RequestParams.new( @engine, @engine.log )
    params.init_multipart "--boundary\nno file name here\n"

    assert_match( /\ACould not read the uploaded file: /, @engine.heap.error.value )
  end

end
