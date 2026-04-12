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
  DYNAMIC = 'dynamic'.freeze
  NODES = 'nodes'.freeze

  CONTEXT = 'context'.freeze
  OPTIONS = 'options'.freeze
  OPTIONS_KEY = 'options_key'.freeze

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
  # Is this a dynamic command?
  # It is dynamic if there is a dynamic child.
  # If so, it has contextual data.
  # 
  def dynamic?
    o = find_child DYNAMIC
    return true if o
    return false
  end

  # 
  # Get the dynamic key for this command.
  # 
  def dynamic_key
    o = find_child DYNAMIC
    return o ? o.value : nil
  end

  def context
    o = find_child CONTEXT
    return o ? o : nil
  end

  #
  # Get the options key for this command.
  #
  def options_key
    o = find_child OPTIONS_KEY
    return o ? o.value : nil
  end

  #
  # Get the options for this command.
  #
  def options
    arr = []
    o = find_child OPTIONS

    if o
      arr = o.children.map { |child| child.value }
    end

    return arr
  end

  # 
  # Get the child nodes for this command.
  # 
  def nodes
    o = find_child NODES
    return o ? o : nil
  end

  # 
  # Run the action script.
  #
  def run_action
    o = find_child ACTION
    return unless o

    Gloo::Exec::Dispatch.message( @engine, 'run', o )
  end

  def run_action_with_context( context )
    o = find_child ACTION
    return unless o

    ctx = find_child CONTEXT
    ctx.set_value( context ) if ctx
    
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
      shell.add_command( self, get_command_data )

      # Are there options to add?
      if options_key
        shell.set_context( options_key, options )
      end
    end
  end


  # ---------------------------------------------------------------------
  #    Helpers
  # ---------------------------------------------------------------------

  # 
  # Get the child nodes for this command.
  # 
  def get_child_nodes
    data = nodes.children.map do |child|
      child.get_command_data
    end

    return data
  end

  # 
  # Get the command data for this command.
  # 
  def get_command_data
    if dynamic?
      return {
        name: name,
        description: description,
        dynamic: true,
        obj: pn,
        method: "cmd_obj_action_with_context",
        source: dynamic_key
      }
    elsif nodes
      return {
        name: name,
        description: description,
        children: get_child_nodes
      }
    else
      return {
        name: name,
        description: description,
        method: "cmd_obj_action",
        obj: pn
      }
    end
  end

end
