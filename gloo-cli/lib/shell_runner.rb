# 
# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# A shell runner.
#
require "readline"

class ShellRunner

  DEFAULT_PROMPT = " -> "
  UNKNOWN_COMMAND = "Unknown command".freeze
  
  # 
  # Initialize the shell runner
  # 
  # @param obj [Object] The shell obj.
  # 
  def initialize( engine, obj )
    @engine = engine
    @obj = obj
    @context = ShellContext.new
    @root = CommandNode.new( nil )
  end


  # ---------------------------------------------------------------------
  #    Shell, control, start and stop
  # ---------------------------------------------------------------------
  
  # 
  # Start the shell.
  # 
  def start
    repl
  end

  # 
  # Flag the shell as done, next time through the loop it will stop
  # 
  def stop
    @context.done = true
  end
  
  # 
  # Get the prompt string
  # 
  def prompt
    p = @obj.prompt 
    return p ? p + ' ' : DEFAULT_PROMPT
  end

  #
  # Handle an empty command — run on_empty_command if defined, otherwise do nothing.
  #
  def handle_empty_command
    @obj.run_on_empty_cmd
  end

  #
  # Handle an unknown command — run on_unknown_cmd if defined, otherwise show default message.
  #
  def handle_unknown_command
    @obj.run_on_unknown_cmd || puts( UNKNOWN_COMMAND )
  end

  #
  # Quit the shell.
  #
  def cmd_quit( obj, context )
    puts "Quitting…"
    context.done = true
  end

  # 
  # Run an action on an object.
  # 
  def cmd_obj_action( obj, context )
    pn = Gloo::Core::Pn.new( @engine, obj )
    command = pn.resolve
    if command
      command.run_action
    end
  end

  #
  # Run an action on an object with context.
  #
  def cmd_obj_action_with_context( cmd_node, parent_node = nil )
    if parent_node
      pn = Gloo::Core::Pn.new( @engine, parent_node.obj )
      command = pn.resolve
      if command
        begin
          command.run_action_with_context( cmd_node.name )
        rescue => e
          command.run_on_error || @obj.run_on_error
        end
      end
    end
  end


  # ---------------------------------------------------------------------
  #    Context
  # ---------------------------------------------------------------------

  # 
  # Set a context list.
  # 
  def set_context key, value_list
    @context.set( key, value_list )
  end


  # ---------------------------------------------------------------------
  #    Tree building
  # ---------------------------------------------------------------------

  # 
  # Execute a command.
  # 
  def execute_command( command_node, args, parent_node = nil )
    if command_node.respond_to?( :method ) && command_node.method
      send( command_node.method, command_node.obj, @context )
    else
      if command_node.name && command_node.name != "" && !command_node.description.empty?
        puts "#{command_node.description}: #{command_node.name}"
      elsif command_node.name
        # puts "Showing: #{command_node.name}"
        cmd_obj_action_with_context( command_node, parent_node )
      end
    end
  end


  # 
  # Build a command node from data.
  # 
  def build_node_from_data( data )
    if data[:dynamic]
      CommandNode.new(data[:name], description: data[:description], obj: data[:obj]) do |ctx|
        ctx.send(data[:source]).map do |item|
          CommandNode.new(item)
        end
      end
    elsif data[:children]
      CommandNode.new(data[:name], description: data[:description], method: data[:method], obj: data[:obj]) do |ctx|
        data[:children].map { |child_data| build_node_from_data(child_data) }
      end
    else
      CommandNode.new(data[:name], description: data[:description], method: data[:method], obj: data[:obj])
    end
  end

  # 
  # Add a command node to the root dynamically
  # 
  # @param command_data [Hash] The command data hash
  # 
  # Add a single command dynamically
  # 
  def add_command_node( command_data)
    node = build_node_from_data(command_data)
    
    # Get existing children block or create new one
    existing_block = @root.instance_variable_get(:@children_block)
    
    if existing_block
      # Store existing nodes and add new one
      existing_nodes = existing_block.call(@context)
      all_nodes = existing_nodes + [node]
      @root.instance_variable_set(:@children_block, proc { |ctx| all_nodes })
    else
      # Create new children block with just this node
      @root.instance_variable_set(:@children_block, proc { |ctx| [node] })
    end
    
    node
  end


  # ---------------------------------------------------------------------
  #    REPL
  # ---------------------------------------------------------------------

  #
  # Execute a single command from the given tokens and return.
  # Used when a command is passed directly from the CLI.
  #
  def execute_once( tokens )
    result = traverse( @root, tokens )
    if result[:node]
      @obj.run_before_action
      execute_command( result[:node], tokens, result[:parent] )
      @obj.run_after_action
    else
      handle_unknown_command
    end
  end

  #
  # Traverse the command tree to find the matching node
  # 
  # @param node [CommandNode] The current node
  # @param tokens [Array<String>] The tokens to traverse
  # 
  # @return [Hash] Hash with :node and :parent keys
  # 
  def traverse( node, tokens )
    current = node
    parent = nil

    tokens.each do |token|
      children = current.children( @context )
      match = children.find { |c| c.name == token }
      return { node: nil, parent: nil } unless match
      
      parent = current
      current = match
    end

    { node: current, parent: parent }
  end

  # 
  # Setup readline completion
  # 
  def setup_completion
    Readline.completion_append_character = " "
    Readline.basic_word_break_characters = " \t\n\"\\'`@$><=;|&{("

    Readline.completion_proc = proc do |input|
      buffer = Readline.line_buffer
      tokens = buffer.split(" ")

      tokens << "" if buffer.end_with?(" ")

      result = traverse( @root, tokens[0..-2] )
      current = result[:node]

      # An unrecognized command prefix means there's nothing to complete —
      # fall back to no matches instead of crashing on a nil node.
      next [] unless current

      options = current.children( @context ).map( &:name )

      matches = options.grep(/^#{Regexp.escape(input)}/)

      if matches.length > 1
        puts
        current.children( @context ).each do |child|
          if matches.include?( child.name )
            puts "#{child.name.ljust(15)} #{child.description}"
          end
        end
        print "#{prompt}#{buffer}"
      end

      matches
    end
  end


  # 
  # Run the REPL loop.
  # 
  def repl
    setup_completion

    while ( ! @context.done && (line = Readline.readline(prompt, true)) )
      tokens = line.strip.split(" ")
      if tokens.empty?
        handle_empty_command
        next
      end

      result = traverse( @root, tokens )

      if result[:node]
        @obj.run_before_action
        execute_command( result[:node], tokens, result[:parent] )
        @obj.run_after_action
      else
        handle_unknown_command
      end
    end
  end

end
