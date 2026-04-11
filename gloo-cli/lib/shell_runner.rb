require "readline"

class CommandNode
  attr_reader :name, :description, :method

  def initialize(name, description: "", method: nil, &children_block)
    @name = name
    @description = description
    @method = method
    @children_block = children_block
  end

  def children(context)
    return [] unless @children_block
    @children_block.call(context)
  end
end



class Context

  attr_accessor :done
  attr_reader :projects, :tasks
 
  def initialize
    @projects = ["alpha", "beta", "gamma"]
    @tasks = ["task1", "task2"]
  end

end

# 
# Get the prompt string
# 
def prompt
  return " -> "
end


# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# A CLI shell.
#

class Shell < Gloo::Core::Obj

  def run
    context = Context.new

    root = build_tree

    repl(root, context)
  end


  def cmd_quit(context)
    puts "Quitting…"
    context.done = true
  end

  def cmd_add(context)
    puts "Adding project…"
    context.projects << "X"
  end

  def cmd_projects(context)
    puts "Listing projects…"
    context.projects.each { |proj| puts "  - #{proj}" }
  end

  def cmd_tasks(context)
    puts "Listing tasks…"
    context.tasks.each { |task| puts "  - #{task}" }
  end

  def execute_command(command_node, context, args)
    if command_node.respond_to?(:method) && command_node.method
      send(command_node.method, context)
    else
      if command_node.name && command_node.name != "" && !command_node.description.empty?
        puts "#{command_node.description}: #{command_node.name}"
      elsif command_node.name
        puts "Showing: #{command_node.name}"
      end
    end
  end


  def command_data
    [
      {
        name: "add",
        description: "add a project",
        method: "cmd_add"
      },
      {
        name: "list",
        description: "List resources",
        children: [
          {
            name: "projects",
            description: "List projects",
            method: "cmd_projects"
          },
          {
            name: "tasks",
            description: "List tasks",
            method: "cmd_tasks"
          }
        ]
      },
      {
        name: "show",
        description: "Show a resource",
        children: [
          {
            name: "project",
            description: "Show a project",
            dynamic: true,
            source: "projects"
          },
          {
            name: "task",
            description: "Show a task",
            dynamic: true,
            source: "tasks"
          }
        ]
      },
      {
        name: "quit",
        description: "Quit the application",
        method: "cmd_quit"
      }
    ]
  end


  def build_node_from_data(data)
    if data[:dynamic]
      CommandNode.new(data[:name], description: data[:description]) do |ctx|
        ctx.send(data[:source]).map do |item|
          CommandNode.new(item)
        end
      end
    elsif data[:children]
      CommandNode.new(data[:name], description: data[:description], method: data[:method]) do |ctx|
        data[:children].map { |child_data| build_node_from_data(child_data) }
      end
    else
      CommandNode.new(data[:name], description: data[:description], method: data[:method])
    end
  end


  def build_tree
    CommandNode.new(nil) do |ctx|
      command_data.map { |data| build_node_from_data(data) }
    end
  end



  def traverse(node, tokens, context)
    current = node

    tokens.each do |token|
      children = current.children(context)
      match = children.find { |c| c.name == token }
      return nil unless match
      current = match
    end

    current
  end

  def setup_completion(root, context)
    Readline.completion_append_character = " "
    Readline.basic_word_break_characters = " \t\n\"\\'`@$><=;|&{("

    Readline.completion_proc = proc do |input|
      buffer = Readline.line_buffer
      tokens = buffer.split(" ")

      tokens << "" if buffer.end_with?(" ")

      current = traverse(root, tokens[0..-2], context)
      options = current.children(context).map(&:name)

      matches = options.grep(/^#{Regexp.escape(input)}/)

      if matches.length > 1
        puts
        current.children(context).each do |child|
          if matches.include?(child.name)
            puts "#{child.name.ljust(15)} #{child.description}"
          end
        end
        print "#{prompt}#{buffer}"
      end

      matches
    end
  end


  def repl(root, context)
    setup_completion(root, context)

    while ( !context.done && (line = Readline.readline(prompt, true)) )
      tokens = line.strip.split(" ")
      next if tokens.empty?

      node = traverse(root, tokens, context)

      if node
        execute_command(node, context, tokens)
      else
        puts "Unknown command"
      end
    end
  end

end
