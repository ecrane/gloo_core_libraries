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
  INCLUDE_QUIT = 'include_quit'.freeze

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

  # 
  # Get the value of the include_quit child object.
  # Returns false if there is none.
  #
  def include_quit?
    o = find_child INCLUDE_QUIT
    return o.value if o
    return false
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
  # Get the shell runner or initialize it if it doesn't exist.
  #
  def get_runner
    return @runner ||= ShellRunner.new( @engine, self )
  end
  
  #
  # Start the shell.
  #
  def msg_start
    runner = get_runner

    # add_test_commands
    add_quit_command

    runner.start
  end

  #
  # Stop the shell.
  #
  def msg_stop
    @runner.stop if @runner
  end

  #
  # Add a command to the shell.
  #
  def add_command obj, command_data
    runner = get_runner
    runner.add_command_node( command_data )
  end

  
  # ---------------------------------------------------------------------
  #    Context
  # ---------------------------------------------------------------------

  def set_context key, value
    @runner.set_context( key, value )
  end


  # ---------------------------------------------------------------------
  #    Commands
  # ---------------------------------------------------------------------

  #
  # Quit the shell.
  #
  def add_quit_command
    return unless include_quit?
    
    @runner.add_command_node({
      name: "quit",
      description: "Quit the application", 
      method: "cmd_quit"
    })
  end

  # def add_test_commands
  #   @runner.add_command_node({
  #     name: "add",
  #     description: "add a project",
  #     method: "cmd_add"
  #   })

  #   @runner.add_command_node({
  #     name: "show",
  #     description: "show a resource",
  #     children: [
  #       {
  #         name: "project",
  #         description: "show a project",
  #         dynamic: true,
  #         source: "projects"
  #       },
  #       {
  #         name: "task",
  #         description: "show a task",
  #         dynamic: true,
  #         source: "tasks"
  #       }
  #     ]
  #   })

  #   @runner.add_command_node({
  #     name: "list",
  #     description: "list resources",
  #     children: [
  #       {
  #         name: "projects",
  #         description: "list projects",
  #         method: "cmd_projects"
  #       },
  #       {
  #         name: "tasks",
  #         description: "list tasks",
  #         method: "cmd_tasks"
  #       }
  #     ]
  #   })
  # end

end
