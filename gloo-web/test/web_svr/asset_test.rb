# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# Only covers the pure path/type helpers and lookup logic. The
# route-building side (add_asset_routes and friends) needs a real
# project asset folder and a running server's pages container - out
# of scope here, see the story notes.
#
require 'test_helper'
require 'ostruct'
require 'tmpdir'

class AssetTest < BaseEngineTest

  def create_svr
    o = @engine.parser.parse_immediate 'create s as svr'
    o.run
    return @engine.heap.root.children.first
  end

  def build_asset
    return WebSvr::Asset.new( @engine, create_svr )
  end

  def test_is_asset_matches_only_the_asset_folder_name
    asset = build_asset
    assert asset.is_asset?( 'asset' )
    refute asset.is_asset?( 'assets' )
    refute asset.is_asset?( 'image' )
  end

  def test_type_for_file_recognizes_css_js_and_favicon
    asset = build_asset
    assert_equal WebSvr::Asset::CSS_TYPE, asset.type_for_file( 'style.css' )
    assert_equal WebSvr::Asset::JS_TYPE, asset.type_for_file( 'app.js' )
    assert_equal WebSvr::Asset::FAVICON_TYPE, asset.type_for_file( 'favicon.ico' )
  end

  def test_type_for_file_falls_back_to_an_image_mime_type
    asset = build_asset
    assert_equal 'image/png', asset.type_for_file( 'logo.png' )
    assert_equal 'image/jpg', asset.type_for_file( 'photo.jpg' )
  end

  def test_asset_folder_paths_are_built_under_the_project_path
    asset = build_asset
    project = @engine.settings.project_path

    assert_equal File.join( project, 'asset' ), asset.asset_folder
    assert_equal File.join( project, 'asset', 'image' ), asset.image_folder
    assert_equal File.join( project, 'asset', 'stylesheet' ), asset.stylesheet_folder
    assert_equal File.join( project, 'asset', 'javascript' ), asset.javascript_folder
  end

  def test_common_asset_folder_is_nil_when_the_lib_has_none
    asset = build_asset
    assert_nil asset.common_asset_folder
  end

  def test_path_for_file_returns_the_files_own_value_when_it_already_exists
    Dir.mktmpdir do |dir|
      real_file = File.join( dir, 'present.png' )
      File.write( real_file, 'data' )

      asset = build_asset
      file = OpenStruct.new( value: real_file )

      assert_equal real_file, asset.path_for_file( file )
    end
  end

  def test_path_for_file_falls_back_to_the_asset_folder_when_not_found_directly
    asset = build_asset
    file = OpenStruct.new( value: 'missing.png' )

    expected = File.join( asset.asset_folder, 'missing.png' )
    assert_equal expected, asset.path_for_file( file )
  end

end
