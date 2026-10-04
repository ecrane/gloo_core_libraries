# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# A YAML file object. Holds a path to a YAML file and supports
# loading and saving named fields via a container object.
#
require 'yaml'
require 'date'

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
  # It is true when the file was loaded, false if it couldn't be.
  #
  def msg_load
    container = param_container( 'load' )
    return @engine.heap.it.set_to( false ) unless container

    path = resolve_path
    return @engine.heap.it.set_to( false ) unless path

    data = read_yaml_file( path )
    return @engine.heap.it.set_to( false ) unless data

    container.children.each do |child|
      key = child.name
      next unless data.key?( key )

      # Nested data is planned for an upcoming release; until then a
      # nested block or list is skipped, not loaded as Ruby's text for it.
      if nested?( data[ key ] )
        warn_nested( key )
        next
      end

      child.set_value scalar_text( data[ key ] )
    end
    @engine.heap.it.set_to true
  end

  #
  # Save fields from a container into the YAML file.
  # The param is a path to a container object whose children
  # are matched by name to YAML keys. Creates the file if it does
  # not exist; keys without a matching child are kept.
  #
  def msg_save
    container = param_container( 'save' )
    return unless container

    path = resolve_path
    return unless path

    data = {}
    if File.exist?( path )
      data = read_yaml_file( path )
      # The file couldn't be read (reported); don't overwrite it.
      return unless data
    end

    container.children.each do |child|
      key = child.name

      # Nested data is planned for an upcoming release; until then a
      # nested block or list in the file is left as it is.
      if nested?( data[ key ] )
        warn_nested( key )
        next
      end

      data[ key ] = child.value
    end

    file_op( 'write', path ) { File.write( path, data.to_yaml ) }
  end


  # ---------------------------------------------------------------------
  #    Helpers
  # ---------------------------------------------------------------------

  private

  #
  # Resolve the container named by the first param. Reports a syntax
  # error if there's no param, or an error if the container doesn't
  # exist, and returns nil.
  #
  def param_container( msg )
    unless @params&.token_count&.positive?
      @engine.syntax_err "Missing the container to #{msg}! eg. tell #{name} to #{msg} (data)"
      return nil
    end

    container = Gloo::Core::Pn.new( @engine, @params.first ).resolve
    @engine.err Gloo::Core::NotFound.object( @params.first ) unless container
    return container
  end

  #
  # Get the expanded path of the YAML file (the object's value).
  # Reports an error and returns nil if there's no path.
  #
  def resolve_path
    if self.value.to_s.strip.empty?
      @engine.err "yaml '#{name}' has no path; put a file path into #{name} first."
      return nil
    end

    return File.expand_path( self.value )
  end

  #
  # Read and parse the YAML file. Returns a hash of its keys, or nil
  # after reporting an error: a missing or unreadable file, invalid
  # YAML, or YAML that isn't key: value pairs. Dates and times are
  # allowed.
  #
  def read_yaml_file( path )
    unless File.exist?( path )
      @engine.err Gloo::Core::NotFound.file( path )
      return nil
    end

    content = file_op( 'read', path ) { File.read( path ) }
    return nil unless content

    data = YAML.safe_load( content, permitted_classes: [ Date, Time ] ) || {}
    return data if data.is_a?( Hash )

    return yaml_err( path, 'it is not a list of key: value pairs' )
  rescue Psych::SyntaxError => e
    return yaml_err( path, e.problem )
  rescue Psych::Exception => e
    return yaml_err( path, e.message )
  end

  #
  # Report YAML that can't be used, and return nil.
  #
  def yaml_err( path, reason )
    @engine.err "Couldn't read the YAML in '#{path}': #{reason}."
    return nil
  end

  #
  # Run a file operation, reporting a failure (eg. no permission, a
  # missing folder) as an error. Returns nil if it failed.
  #
  def file_op( action, path )
    return yield
  rescue SystemCallError => e
    @engine.err "Could not #{action} '#{path}': #{e.message}"
    return nil
  end

  #
  # Is the value a nested block or a list (not yet supported)?
  #
  def nested?( val )
    return val.is_a?( Hash ) || val.is_a?( Array )
  end

  #
  # Warn that a nested block or list was left unchanged.
  #
  def warn_nested( key )
    @engine.warn "YAML key '#{key}' is a nested block or list, which isn't supported yet; it was left unchanged."
  end

  #
  # The text for a simple YAML value. YAML reads a time with no zone
  # as UTC, so times are shown in UTC rather than converted to local
  # time (the same as gloo-md's md_doc).
  #
  def scalar_text( val )
    return val.utc.strftime( '%Y-%m-%d %H:%M:%S UTC' ) if val.is_a?( Time )

    return val.to_s
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
        'load ({container.path}) — Load fields from the YAML file into the given container. Children of the container are matched by name to YAML keys; dates and times load as text. A parameter is required. It is true when the file was loaded, false if it could not be.',
        'save ({container.path}) — Save fields from the given container into the YAML file, matching container children by name to YAML keys. Creates the file if it does not exist; keys with no matching child are kept. A parameter is required.'
      ],
      :notes => 'Errors: no container (a syntax error), a container ' \
        'that does not exist, an empty path, a file that does not ' \
        'exist or cannot be read or written, and YAML that is not ' \
        'valid or is not key: value pairs. load puts false in it on ' \
        'an error; save does not overwrite a file it could not read. ' \
        'Nested blocks and lists are not supported yet (planned for ' \
        'an upcoming release): load skips them with a warning, and ' \
        'save leaves them in the file as they are.',
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
