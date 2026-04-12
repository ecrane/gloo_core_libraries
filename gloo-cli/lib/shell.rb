# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# A CLI shell.
#

class Shell < Gloo::Core::Obj

  KEYWORD = 'shell'.freeze
  KEYWORD_SHORT = 'shell'.freeze
  PROMPT = 'prompt'.freeze
  DEFAULT_ACTION = 'default_action'.freeze

  #
  # The name of the object type.
  #
  def self.typename
    return KEYWORD
  end

  #
  # The short name of the object type.
  #
  def self.short_typename
    return KEYWORD_SHORT
  end

  #
  # Get the value of the prompt child object.
  # Returns nil if there is none.
  #
  def prompt
    o = find_child PROMPT
    return '' unless o

    return o.value
  end

  
  # ---------------------------------------------------------------------
  #    Children
  # ---------------------------------------------------------------------

  #
  # Does this object have children to add when an object
  # is created in interactive mode?
  # This does not apply during obj load, etc.
  #
  def add_children_on_create?
    return true
  end

  #
  # Add children to this object.
  # This is used by containers to add children needed
  # for default configurations.
  #
  def add_default_children
    fac = @engine.factory
    fac.create_string PROMPT, '> ', self
    fac.create_script DEFAULT_ACTION, '', self
  end


  # ---------------------------------------------------------------------
  #    Messages
  # ---------------------------------------------------------------------

  #
  # Get a list of message names that this object receives.
  #
  def self.messages
    return super + [ 'start', 'stop' ]
  end

  #
  # Start the shell.
  #
  def msg_start
    @runner = ShellRunner.new( self )

    @runner.add_command_node({
      name: "done",
      description: "Exit the shell", 
      method: "cmd_quit"
    })

    @runner.start
  end

  #
  # Stop the shell.
  #
  def msg_stop
    @runner.stop if @runner
  end

end
