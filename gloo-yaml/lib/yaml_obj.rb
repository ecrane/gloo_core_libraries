# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# A YAML file object. Holds a path to a YAML file and supports
# loading and saving named fields via a container object.
#
require 'yaml'

class YamlObj < Gloo::Core::Obj

  KEYWORD       = 'yaml'.freeze
  KEYWORD_SHORT = 'yml'.freeze

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
  # Set the value with any necessary type conversions.
  #
  def set_value( new_value )
    self.value = new_value.to_s
  end


  # ---------------------------------------------------------------------
  #    Messages
  # ---------------------------------------------------------------------

  #
  # Get a list of message names that this object receives.
  #
  def self.messages
    return super + %w[load save]
  end

  #
  # Load fields from the YAML file into a container.
  # The param is a path to a container object whose children
  # are matched by name to YAML keys.
  #
  def msg_load
    return unless @params&.token_count&.positive?

    container = resolve_container
    return unless container

    data = read_yaml_file
    return unless data

    container.children.each do |child|
      key = child.name
      child.set_value data[ key ].to_s if data.key?( key )
    end
  end

  #
  # Save fields from a container into the YAML file.
  # The param is a path to a container object whose children
  # are matched by name to YAML keys.
  #
  def msg_save
    return unless @params&.token_count&.positive?

    container = resolve_container
    return unless container

    data = read_yaml_file || {}

    container.children.each do |child|
      data[ child.name ] = child.value
    end

    write_yaml_file data
  end


  # ---------------------------------------------------------------------
  #    Helpers
  # ---------------------------------------------------------------------

  private

  #
  # Resolve the container object from the first param.
  #
  def resolve_container
    pn = Gloo::Core::Pn.new( @engine, @params.first )
    pn.resolve
  end

  #
  # Read and parse the YAML file. Returns a hash, or nil on error.
  #
  def read_yaml_file
    path = File.expand_path( self.value )
    unless File.exist?( path )
      @engine.log.error "YAML file not found: #{path}"
      return nil
    end
    YAML.load_file( path ) || {}
  end

  #
  # Serialize data hash and write it back to the YAML file.
  #
  def write_yaml_file( data )
    path = File.expand_path( self.value )
    File.write( path, data.to_yaml )
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
      :description => 'A YAML file object. Holds a path to a YAML ' \
        'file (as its own value) and supports loading and saving ' \
        'named fields via a container object.',
      :messages => [
        'load ({container.path}) — Load fields from the YAML file into the given container. Children of the container are matched by name to YAML keys. A parameter is required.',
        'save ({container.path}) — Save fields from the given container into the YAML file, matching container children by name to YAML keys. A parameter is required.'
      ],
      :notes => 'No vault documentation exists for this object type — ' \
        'this was authored directly from the code.',
      :examples => <<~EXAMPLES.strip
        settings [can] :
          path [yaml] : ~/.my_app/settings.yml
          data [can] :
            name [string] :
            theme [string] :
          on_load [script] :
            tell path to load (data)
            put 'dark' into data.theme
            tell path to save (data)
      EXAMPLES
    }
  end

end
