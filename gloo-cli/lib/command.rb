# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# A CLI command.
#

class Command < Gloo::Core::Obj

  KEYWORD = 'command'.freeze
  KEYWORD_SHORT = 'command'.freeze
  NAME = 'name'.freeze
  DESCRIPTION = 'description'.freeze
  ACTION = 'action'.freeze
  DYNAMIC = 'dynamic'.freeze
  NODES = 'nodes'.freeze

  CONTEXT = 'context'.freeze
  OPTIONS = 'options'.freeze
  OPTIONS_KEY = 'options_key'.freeze
  ON_ERROR = 'on_error'.freeze

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

  #
  # Run the action script with context.
  #
  def run_action_with_context( context )
    o = find_child ACTION
    return unless o

    ctx = find_child CONTEXT
    ctx.set_value( context ) if ctx

    Gloo::Exec::Dispatch.message( @engine, 'run', o )
  end

  #
  # Run the on_error script if one exists.
  # Returns true if the script was found and run, false otherwise.
  #
  def run_on_error
    o = find_child ON_ERROR
    return false unless o

    Gloo::Exec::Dispatch.message( @engine, 'run', o )
    return true
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

  # ---------------------------------------------------------------------
  #    Object Documentation
  # ---------------------------------------------------------------------

  #
  # Get the object's documentation data.
  #
  def self.doc_data
    {
      :name => KEYWORD,
      :shortcut => KEYWORD_SHORT,
      :description => 'A single command in a shell\'s command tree. ' \
        'Register it with a shell (via the register message) to make ' \
        'it selectable at that shell\'s prompt; when selected, its ' \
        'action script runs.',
      :children => [
        'name (string) — The command\'s name, as typed at the shell prompt.',
        'description (string) — Shown alongside the command name when the shell lists its options.',
        'action (script) — Run when the command is selected.',
        'dynamic (string) — Optional. Marks this as a dynamic command whose children are generated at runtime from a named shell context list (set via a sibling command\'s options_key, or directly via Shell#set_context), rather than being declared up front.',
        'nodes (container) — Optional. A container of child command objects, for a nested command tree under this one.',
        'context (string) — Populated automatically with the selected child\'s name when a dynamic command\'s action runs.',
        'options (container) — Optional. A fixed list of values for a dynamic command\'s source list, registered under options_key.',
        'options_key (string) — Optional. The shell context key that options gets registered under.'
      ],
      :messages => [
        'register ({shell.path}) — Register this command with the given shell object, adding it to that shell\'s command tree. A parameter is required: the path to the shell.'
      ],
      :notes => 'No vault documentation exists for this object type — ' \
        'this was authored directly from the code.'
    }
  end

end
