# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
require 'test_helper'
require 'tmpdir'

class ShellTest < BaseEngineTest

  def test_doc_data
    data = Shell.doc_data
    assert_equal Shell.typename, data[ :name ]
    assert_equal Shell.short_typename, data[ :shortcut ]
  end

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

  # ---------------------------------------------------------------------
  #    A shell is an app: it doesn't start in Script mode
  # ---------------------------------------------------------------------

  def test_start_in_script_mode_is_an_error_naming_the_app_folder
    Dir.mktmpdir do |dir|
      dir = File.realpath( dir )
      File.write( File.join( dir, 'start.gloo' ), "start [can] :\n" )
      @engine.persist_man.load( File.join( dir, 'start.gloo' ) )
      sh = create_shell
      script_mode

      @engine.parser.run 'tell sh to start'
      assert @engine.error?
      assert_equal format( Shell::NOT_IN_SCRIPT_MODE_ERR, dir ), @engine.heap.error.value
      assert_nil sh.instance_variable_get( :@runner ), 'expected the shell not to start'
    end
  end

  def test_start_in_script_mode_with_no_file_uses_a_placeholder_folder
    create_shell
    script_mode

    @engine.parser.run 'tell sh to start'
    assert_equal format( Shell::NOT_IN_SCRIPT_MODE_ERR, '<folder>' ), @engine.heap.error.value
    refute @engine.heap.it.value
  end

  def test_start_outside_script_mode_starts_the_runner
    sh = create_shell
    started = []
    runner = Object.new
    runner.define_singleton_method( :start ) { started << true }
    sh.define_singleton_method( :get_runner ) { runner }

    @engine.parser.run 'tell sh to start'
    refute @engine.error?
    assert_equal [ true ], started
  end

  private

  #
  # Make the engine report that it's running in Script mode.
  #
  def script_mode
    @engine.define_singleton_method( :mode ) { Gloo::App::Mode::SCRIPT }
  end

end
