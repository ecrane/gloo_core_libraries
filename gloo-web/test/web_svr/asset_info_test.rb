# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
require 'test_helper'
require 'tmpdir'

class AssetInfoTest < BaseEngineTest

  #
  # AssetInfo indexes registered assets in class variables shared
  # across the whole process - reset them so tests don't leak into
  # each other or into a real app's asset list.
  #
  def setup
    super
    WebSvr::AssetInfo.class_variable_set( :@@index_by_pn, {} )
    WebSvr::AssetInfo.class_variable_set( :@@index_by_published, {} )
  end

  def with_temp_asset
    Dir.mktmpdir do |dir|
      full_path = File.join( dir, 'logo.png' )
      File.write( full_path, 'fake image bytes' )
      yield full_path
    end
  end

  def test_register_computes_a_hash_and_published_name
    with_temp_asset do |full_path|
      info = WebSvr::AssetInfo.new( @engine, full_path, 'logo.png', '/asset/image/logo.png' )
      info.register

      refute_nil info.hash
      assert_equal "logo-#{info.hash}.png", info.published_name
      assert_equal "/asset/image/logo-#{info.hash}.png", info.published_pn
    end
  end

  def test_register_indexes_by_pn_and_published_pn
    with_temp_asset do |full_path|
      info = WebSvr::AssetInfo.new( @engine, full_path, 'logo.png', '/asset/image/logo.png' )
      info.register

      assert_same info, WebSvr::AssetInfo.find_info_for( info.published_pn )
      assert_equal info.published_pn, WebSvr::AssetInfo.find_published_name_for( info.pn )
    end
  end

  def test_find_published_name_for_returns_nil_when_unregistered
    assert_nil WebSvr::AssetInfo.find_published_name_for( '/asset/does/not/exist.png' )
  end

  def test_find_published_name_for_returns_nil_for_a_nil_pn
    assert_nil WebSvr::AssetInfo.find_published_name_for( nil )
  end

  def test_find_info_for_returns_nil_when_unregistered
    assert_nil WebSvr::AssetInfo.find_info_for( '/asset/does/not/exist-abc123.png' )
  end

end
