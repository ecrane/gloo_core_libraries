# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# A CLI command.
#

class Command < Gloo::Core::Obj

  KEYWORD = 'command'.freeze
  KEYWORD_SHORT = 'command'.freeze
  DESCRIPTION = 'description'.freeze
  ACTION = 'action'.freeze

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
  # Get the description of the command.
  # 
  def description
    o = find_child DESCRIPTION
    return '' unless o

    return o.value
  end

  # 
  # Run the action script.
  #
  def run_action
    o = find_child ACTION
    return unless o

    Gloo::Exec::Dispatch.message( @engine, 'run', o )
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
    fac.create_string NAME, '', self
    fac.create_string DESCRIPTION, '', self
    fac.create_script ACTION, '', self
  end


  # ---------------------------------------------------------------------
  #    Messages
  # ---------------------------------------------------------------------

  #
  # Get a list of message names that this object receives.
  #
  def self.messages
    return super + [ 'register' ]
  end

  #
  # Register the command with the shell.
  #
  def msg_register
    if @params&.token_count&.positive?
      pn = Gloo::Core::Pn.new( @engine, @params.first )
      shell = pn.resolve
      shell.add_command self
    end
  end


  # ---------------------------------------------------------------------
  #    Helpers
  # ---------------------------------------------------------------------


end
