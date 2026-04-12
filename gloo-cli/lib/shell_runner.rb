# 
# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# A shell runner.
#
require "readline"

class ShellRunner

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
    return p ? p + ' ' : " -> "
  end

  # 
  # Quit the shell.
  # 
  def cmd_quit( obj, context )
    puts "Quitting…"
    context.done = true
  end

  def cmd_obj_action( obj, context )
    puts "Object action…"
    puts "Object: #{obj}"
    pn = Gloo::Core::Pn.new( @engine, obj )
    command = pn.resolve
    if command
      command.run_action
    end
  end


  # ---------------------------------------------------------------------
  #    Tree building
  # ---------------------------------------------------------------------

  def cmd_add( obj, context )
    puts "Adding project…"
    context.set(:projects, ["alpha", "beta", "gamma"])
    context.set(:tasks, ["task1", "task2"])
    context.add_to_list( :projects, "delta" )
    context.add_to_list( :tasks, "task3" )
  end

  def cmd_projects( obj, context )
    puts "Listing projects…"
    context.projects.each { |proj| puts "  - #{proj}" }
  end

  def cmd_tasks( obj, context )
    puts "Listing tasks…"
    context.tasks.each { |task| puts "  - #{task}" }
  end

  def execute_command( command_node, args )
    if command_node.respond_to?( :method ) && command_node.method
      send( command_node.method, command_node.obj, @context )
    else
      if command_node.name && command_node.name != "" && !command_node.description.empty?
        puts "#{command_node.description}: #{command_node.name}"
      elsif command_node.name
        puts "Showing: #{command_node.name}"
      end
    end
  end


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
  # Example:
  # 
  # shell_runner.add_command_node({
  #   name: "status",
  #   description: "Show system status", 
  #   method: "cmd_status"
  # })
  # 
  # # Add a command with children
  # shell_runner.add_command_node({
  #   name: "admin",
  #   description: "Administration commands",
  #   children: [
  #     { name: "users", description: "Manage users", method: "cmd_admin_users" }
  #   ]
  # })
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
  # Traverse the command tree to find the matching node
  # 
  # @param node [CommandNode] The current node
  # @param tokens [Array<String>] The tokens to traverse
  # 
  # @return [CommandNode] The matching node or nil
  # 
  def traverse( node, tokens )
    current = node

    tokens.each do |token|
      children = current.children( @context )
      match = children.find { |c| c.name == token }
      return nil unless match
      current = match
    end

    current
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

      current = traverse( @root, tokens[0..-2] )
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
      next if tokens.empty?

      node = traverse( @root, tokens )

      if node
        execute_command( node, tokens )
      else
        puts "Unknown command"
      end
    end
  end

end
