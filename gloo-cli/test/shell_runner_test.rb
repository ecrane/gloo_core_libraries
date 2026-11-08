# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
require 'test_helper'

#
# A minimal stand-in for a Shell obj, providing just the hooks
# ShellRunner calls on it.
#
class FakeShellObj

  attr_accessor :before_action_ran, :after_action_ran
  attr_writer :include_quit

  def include_quit?
    return @include_quit != false
  end

  def prompt
    return '>'
  end

  def run_on_empty_cmd
    return false
  end

  def run_on_unknown_cmd
    return false
  end

  def run_before_action
    @before_action_ran = true
  end

  def run_after_action
    @after_action_ran = true
  end

end

class ShellRunnerTest < BaseEngineTest

  def test_single_command_false_by_default
    r = ShellRunner.new( @engine, FakeShellObj.new )
    refute r.single_command?
  end

  def test_single_command_true_when_command_supplied
    r = ShellRunner.new( @engine, FakeShellObj.new, command: [ 'go' ] )
    assert r.single_command?
  end

  def test_single_command_false_when_command_is_empty
    r = ShellRunner.new( @engine, FakeShellObj.new, command: [] )
    refute r.single_command?
  end

  def test_start_runs_the_single_command_and_does_not_enter_repl
    obj = FakeShellObj.new
    r = ShellRunner.new( @engine, obj, command: [ 'go' ] )
    r.add_command_node( { name: 'go', description: '', method: 'cmd_test_action' } )
    def r.cmd_test_action( _obj, _context )
      @test_action_ran = true
    end

    r.start
    assert r.instance_variable_get( :@test_action_ran )
    assert obj.before_action_ran
    assert obj.after_action_ran
  end

  #
  # A Ruby exception in a command is handled (logged, on_exception),
  # not raised out of the shell.
  #
  def test_an_exception_in_a_command_is_handled
    r = ShellRunner.new( @engine, FakeShellObj.new, command: [ 'go' ] )
    r.add_command_node( { name: 'go', description: '', method: 'cmd_test_action' } )
    def r.cmd_test_action( _obj, _context )
      raise 'boom'
    end
    reported = []
    @engine.define_singleton_method( :handle_exception ) { |e| reported << e.message }

    r.start
    assert_equal [ 'boom' ], reported
  end

  # Ctrl-C at the shell's empty prompt: the hint names the quit
  # command, and the shell carries on.
  def test_ctrl_c_at_an_empty_prompt_shows_the_hint
    shown = with_readline( [ Interrupt, nil ], buffer: '' ) do
      ShellRunner.new( @engine, FakeShellObj.new ).start
    end
    assert_equal [ "Use 'quit' to leave the shell." ], shown
  end

  # With text typed, the line is just dropped.
  def test_ctrl_c_with_text_typed_shows_nothing
    shown = with_readline( [ Interrupt, nil ], buffer: 'hel' ) do
      ShellRunner.new( @engine, FakeShellObj.new ).start
    end
    assert_empty shown
  end

  # No quit command, so no hint.
  def test_no_hint_without_a_quit_command
    obj = FakeShellObj.new
    obj.include_quit = false
    shown = with_readline( [ Interrupt, nil ], buffer: '' ) do
      ShellRunner.new( @engine, obj ).start
    end
    assert_empty shown
  end

  # Ctrl-C during a command stops it and comes back to the prompt: the
  # next line is read and run.
  def test_ctrl_c_during_a_command_comes_back_to_the_prompt
    r = ShellRunner.new( @engine, FakeShellObj.new )
    r.add_command_node( { name: 'spin', description: '', method: 'cmd_spin' } )
    r.add_command_node( { name: 'go', description: '', method: 'cmd_go' } )
    def r.cmd_spin( _obj, _context )
      raise Interrupt
    end
    def r.cmd_go( _obj, _context )
      @went = true
    end
    warnings = capture_warnings do
      with_readline( [ 'spin', 'go', nil ], buffer: '' ) { r.start }
    end
    assert_equal [ 'Stopped by Ctrl-C.' ], warnings
    assert r.instance_variable_get( :@went )
    assert @engine.interrupted?
  end

  private

  #
  # Run the block with Readline answering each of the answers in turn
  # (an exception class is raised, as Ctrl-C raises Interrupt), and
  # line_buffer giving the buffer. Returns what was shown.
  #
  def with_readline( answers, buffer: '' )
    shown = []
    @engine.log.define_singleton_method( :show ) { |msg, *| shown << msg }
    rl = Readline.singleton_class
    rl.alias_method( :__readline, :readline )
    rl.alias_method( :__line_buffer, :line_buffer )
    rl.define_method( :readline ) do |*|
      a = answers.shift
      a.is_a?( Class ) ? raise( a ) : a
    end
    rl.define_method( :line_buffer ) { buffer }
    yield
    return shown
  ensure
    rl.alias_method( :readline, :__readline )
    rl.alias_method( :line_buffer, :__line_buffer )
    rl.send( :remove_method, :__readline, :__line_buffer )
    @engine.log.singleton_class.send( :remove_method, :show )
  end

end
