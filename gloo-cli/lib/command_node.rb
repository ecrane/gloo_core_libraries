# 
# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# A command node.
# Represents a command in the command tree.
#
class CommandNode

  attr_reader :name, :description, :method, :obj

  def initialize( name, description: "", method: nil, obj: nil, &children_block )
    puts "Creating command node: #{name} with obj: #{obj}"
    @name = name
    @description = description
    @method = method
    @obj = obj
    @children_block = children_block
  end

  def children( context )
    return [] unless @children_block
    @children_block.call( context )
  end
end