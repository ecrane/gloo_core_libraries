# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
require 'test_helper'
require 'tmpdir'

class ShellTest < BaseEngineTest

  def create_shell
    i = @engine.parser.parse_immediate 'create sh as shell'
    i.run
    return @engine.heap.root.find_child( 'sh' )
  end

  def test_get_runner_has_no_single_command_outside_app_mode
    sh = create_shell
    runner = sh.get_runner
    refute runner.single_command?
  end

  #
  # In App mode with a trailing CLI parameter, the shell's runner
  # should pick that up as its single command - not from
  # @engine.args.files, which stays empty for App mode (see
  # Gloo::App::Args#process_one_arg in dev/gloo).
  #
  def test_get_runner_picks_up_the_apps_single_command
    Dir.mktmpdir do |root|
      app_engine = Gloo::App::Engine.new(
        Gloo::App::EngineContext.new(
          [ '--app', root, '--quiet', 'status' ], nil, nil, default_user_root ) )
      app_engine.start

      i = app_engine.parser.parse_immediate 'create sh as shell'
      i.run
      sh = app_engine.heap.root.find_child( 'sh' )

      runner = sh.get_runner
      assert runner.single_command?
      assert_empty app_engine.args.files
    end
  end

  def test_with_command_not_created_outside_app_mode
    sh = create_shell
    sh.get_runner
    assert_nil sh.find_child( 'with_command' )
  end

  def test_with_command_created_and_set_when_app_mode_has_a_command
    Dir.mktmpdir do |root|
      app_engine = Gloo::App::Engine.new(
        Gloo::App::EngineContext.new(
          [ '--app', root, '--quiet', 'status' ], nil, nil, default_user_root ) )
      app_engine.start

      i = app_engine.parser.parse_immediate 'create sh as shell'
      i.run
      sh = app_engine.heap.root.find_child( 'sh' )
      sh.get_runner

      wc = sh.find_child( 'with_command' )
      refute_nil wc
      assert_equal 'status', wc.value
    end
  end

  def test_with_command_joins_multiple_tokens
    Dir.mktmpdir do |root|
      app_engine = Gloo::App::Engine.new(
        Gloo::App::EngineContext.new(
          [ '--app', root, '--quiet', 'put', 'foo', 'bar' ], nil, nil, default_user_root ) )
      app_engine.start

      i = app_engine.parser.parse_immediate 'create sh as shell'
      i.run
      sh = app_engine.heap.root.find_child( 'sh' )
      sh.get_runner

      assert_equal 'put foo bar', sh.find_child( 'with_command' ).value
    end
  end

  def test_with_command_updates_a_child_already_declared_by_the_script
    Dir.mktmpdir do |root|
      app_engine = Gloo::App::Engine.new(
        Gloo::App::EngineContext.new(
          [ '--app', root, '--quiet', 'status' ], nil, nil, default_user_root ) )
      app_engine.start

      i = app_engine.parser.parse_immediate 'create sh as shell'
      i.run
      i = app_engine.parser.parse_immediate 'create sh.with_command as string : placeholder'
      i.run
      sh = app_engine.heap.root.find_child( 'sh' )

      sh.get_runner

      assert_equal 1, sh.children.select { |c| c.name == 'with_command' }.count
      assert_equal 'status', sh.find_child( 'with_command' ).value
    end
  end

end
