# 
# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# A shell context.
# Data associated with the shell session.
#
class ShellContext

  attr_accessor :done

  # 
  # Initialize the shell context
  # 
  def initialize
    @done = false
    @properties = {}
  end

  # 
  # Get a property value
  # 
  # @param key [Symbol] The property key
  # @return [Object] The property value
  # 
  def get( key )
    key = key.to_sym
    return @properties[key] if @properties.key?(key)
    
    # If the property doesn't exist, return an empty array
    return []
  end

  # 
  # Set a property value
  # 
  # @param key [Symbol] The property key
  # @param value [Object] The property value
  # 
  def set( key, value )
    @properties[key.to_sym] = value
  end

  # 
  # Add an item to a property list
  # 
  # @param key [Symbol] The property key
  # @param item [Object] The item to add
  # 
  def add_to_list( key, item )
    key = key.to_sym
    list = get(key)
    
    # Ensure we have an array to work with
    list = [] unless list.is_a?(Array)
    
    # Add the item and store the updated list
    list << item
    set(key, list)
    
    list
  end

  # 
  # Check if a property exists
  # 
  # @param key [Symbol] The property key
  # @return [Boolean] True if property exists
  # 
  def has?( key )
    @properties.key?( key.to_sym )
  end

  # 
  # Get all property keys
  # 
  # @return [Array<Symbol>] All property keys
  # 
  def keys
    @properties.keys
  end

  # 
  # Dynamic method access to properties
  # 
  def method_missing( method_name, *args, &block )
    if method_name.to_s.end_with?('=')
      # Setter method: projects=, tasks=, etc.
      key = method_name.to_s.chomp('=').to_sym
      set(key, args.first)
    else
      # Getter method: projects, tasks, etc.
      key = method_name.to_sym
      get(key)
    end
  end

  # 
  # Respond to missing methods for property access
  # 
  def respond_to_missing?( method_name, include_private = false )
    key = method_name.to_s.chomp('=').to_sym
    has?(key) || super
  end

  private

end