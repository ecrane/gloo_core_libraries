# 
# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# A command node.
# Represents a command in the command tree.
#
class CommandNode

  attr_reader :name, :description, :method

  def initialize( name, description: "", method: nil, &children_block )
    @name = name
    @description = description
    @method = method
    @children_block = children_block
  end

  def children( context )
    return [] unless @children_block
    @children_block.call( context )
  end
end