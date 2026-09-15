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

  def prompt
    return '>'
  end

  def run_on_empty_cmd
    return false
  end

  def run_on_unknown_cmd
    return false
  end

  def run_on_error
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

end
