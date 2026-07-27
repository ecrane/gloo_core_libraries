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
  ON_ERROR = 'on_error'.freeze
  ON_UNKNOWN_CMD = 'on_unknown_command'.freeze
  ON_EMPTY_CMD = 'on_empty_command'.freeze
  BEFORE_ACTION = 'before_action'.freeze
  AFTER_ACTION = 'after_action'.freeze

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
  # If CLI args were passed, execute that command once and return.
  # Otherwise, enter the interactive REPL.
  #
  def msg_start
    runner = get_runner

    # add_test_commands
    add_quit_command

    cmd_tokens = @engine.args.files
    if cmd_tokens.any?
      runner.execute_once( cmd_tokens )
    else
      runner.start
    end
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

  #
  # Run the on_unknown_cmd script if one exists.
  # Returns true if the script was found and run, false otherwise.
  #
  def run_on_unknown_cmd
    o = find_child ON_UNKNOWN_CMD
    return false unless o

    Gloo::Exec::Dispatch.message( @engine, 'run', o )
    return true
  end

  #
  # Run the on_empty_command script if one exists.
  # Returns true if the script was found and run, false otherwise.
  #
  def run_on_empty_cmd
    o = find_child ON_EMPTY_CMD
    return false unless o

    Gloo::Exec::Dispatch.message( @engine, 'run', o )
    return true
  end

  #
  # Run the before_action script if one exists.
  #
  def run_before_action
    o = find_child BEFORE_ACTION
    return unless o

    Gloo::Exec::Dispatch.message( @engine, 'run', o )
  end

  #
  # Run the after_action script if one exists.
  #
  def run_after_action
    o = find_child AFTER_ACTION
    return unless o

    Gloo::Exec::Dispatch.message( @engine, 'run', o )
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
      :description => 'A CLI shell — an interactive command-driven ' \
        'REPL, or a one-shot command executor when the app is invoked ' \
        'with extra command-line arguments. Build up the command tree ' \
        'by adding command objects (see the command object type) that ' \
        'register themselves with this shell.',
      :children => [
        "prompt (string) — Default: '> '. The prompt shown at each turn of the REPL.",
        'default_action (script) — Run when the user presses RETURN with no input.',
        'include_quit (boolean) — Optional. If true, a built-in quit command is added automatically.',
        'on_error (script) — Optional. Run when a command raises an error.',
        "on_unknown_command (script) — Optional. Run when the input doesn't match any known command; if absent, a default \"Unknown command\" message is shown instead.",
        'on_empty_command (script) — Optional. Run when the user submits an empty line.',
        'before_action (script) — Optional. Run before every command executes.',
        'after_action (script) — Optional. Run after every command executes.'
      ],
      :messages => [
        'start — Start the shell. If the app was invoked with extra command-line arguments, execute that one command and return; otherwise enter the interactive REPL.',
        'stop — Stop a running shell.'
      ],
      :notes => 'No vault documentation exists for this object type — ' \
        'this was authored directly from the code. Commands attach to ' \
        'a shell either by declaring a command object as a child and ' \
        'sending it the register message with this shell\'s path, or ' \
        'by calling add_command directly. The underlying tree/REPL ' \
        'engine here was later ported into dev/gloo itself (as ' \
        'Gloo::Shell::Runner) to power the interactive help shell.'
    }
  end

end
