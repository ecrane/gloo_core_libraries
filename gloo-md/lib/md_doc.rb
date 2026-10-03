# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# A Markdown document with YAML frontmatter.
# Holds a file path and exposes the frontmatter fields as container
# children and the Markdown body as a text child.
#
require 'yaml'
require 'date'

class MdDoc < Gloo::Core::Obj

  KEYWORD       = 'md_doc'.freeze
  KEYWORD_SHORT = 'md_doc'.freeze

  PATH        = 'path'.freeze
  FRONTMATTER = 'frontmatter'.freeze
  BODY        = 'body'.freeze


  # ---------------------------------------------------------------------
  #    Type identity
  # ---------------------------------------------------------------------

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
  #    Children
  # ---------------------------------------------------------------------

  #
  # Does this object have children to add when an object
  # is created in interactive mode?
  #
  def add_children_on_create?
    return true
  end

  #
  # Add the default children: path, frontmatter, body.
  #
  def add_default_children
    fac = @engine.factory
    fac.create_file PATH, nil, self
    fac.create_can FRONTMATTER, self
    fac.create_text BODY, nil, self
  end


  # ---------------------------------------------------------------------
  #    Messages
  # ---------------------------------------------------------------------

  #
  # Get a list of message names that this object receives.
  #
  def self.messages
    return super + %w[read write]
  end

  #
  # Read the file at path, parse frontmatter and body, populate children.
  # Only scalar frontmatter values (including dates and times) become gloo
  # string children; complex values (arrays, nested hashes) are skipped —
  # they are preserved on write by re-reading the file.
  # It is true when the file was read, false if it couldn't be.
  #
  def msg_read
    path = resolve_path
    return @engine.heap.it.set_to( false ) unless path

    content = read_file( path )
    return @engine.heap.it.set_to( false ) unless content

    fm_hash, body_text = parse_frontmatter( content, path )
    return @engine.heap.it.set_to( false ) unless fm_hash

    fm_can = find_child FRONTMATTER
    # Start from the file's keys only, not ones left from an earlier read.
    fm_can&.delete_children
    if fm_can
      fm_hash.each do |key, val|
        next unless scalar?( val )
        child = fm_can.find_add_child( key.to_s, 'string' )
        child.set_value scalar_text( val )
      end
    end

    body = find_child BODY
    body.set_value( body_text ) if body
    @engine.heap.it.set_to true
  end

  #
  # Serialize frontmatter and body children back to the file at path.
  # Re-reads the current file to get the base hash (preserving arrays and other
  # complex values), then overlays the scalar children that were changed.
  # Creates the file if it does not exist.
  #
  def msg_write
    path = resolve_path
    return unless path

    # Re-read the file so arrays and nested hashes survive unchanged.
    base = {}
    if File.exist?( path )
      content = read_file( path )
      return unless content

      base, _ = parse_frontmatter( content, path )
      # Invalid frontmatter was reported; don't overwrite the file.
      return unless base
    end

    fm_can = find_child FRONTMATTER

    # Overlay changed children; updating an existing key preserves its
    # position, and an unchanged one keeps its YAML type (eg. a date).
    if fm_can
      fm_can.children.each do |child|
        next if base.key?( child.name ) && scalar_text( base[ child.name ] ) == child.value.to_s

        base[ child.name ] = child.value
      end
    end

    body = find_child BODY
    body_text = body ? body.value.to_s : ''

    file_op( 'write', path ) { File.write( path, build_content( base, body_text ) ) }
  end


  # ---------------------------------------------------------------------
  #    Private helpers
  # ---------------------------------------------------------------------

  private

  #
  # True for scalar YAML values that can be stored as gloo string children.
  # Arrays, hashes, and other complex types are skipped on read.
  #
  def scalar?( val )
    val.is_a?( String ) || val.is_a?( Integer ) || val.is_a?( Float ) ||
      val.is_a?( TrueClass ) || val.is_a?( FalseClass ) || val.nil? ||
      val.is_a?( Date ) || val.is_a?( Time )
  end

  #
  # The text for a scalar frontmatter value, as its string child holds it.
  # YAML reads a time with no zone as UTC, so times are shown in UTC
  # (eg. 2026-10-01 09:30:00 UTC) rather than converted to local time.
  #
  def scalar_text( val )
    return val.utc.strftime( '%Y-%m-%d %H:%M:%S UTC' ) if val.is_a?( Time )

    return val.to_s
  end

  #
  # Get the expanded path string from the path child.
  # Reports an error and returns nil if there's no path.
  #
  def resolve_path
    o = find_child PATH
    if o.nil? || o.value.to_s.strip.empty?
      @engine.err "md_doc '#{name}' has no path; put a file path into #{name}.path first."
      return nil
    end

    File.expand_path( o.value.to_s )
  end

  #
  # Read the file at path. Reports an error and returns nil if it's
  # missing or can't be read.
  #
  def read_file( path )
    unless File.exist?( path )
      @engine.err Gloo::Core::NotFound.file( path )
      return nil
    end

    return file_op( 'read', path ) { File.read( path ) }
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
  # Parse YAML frontmatter from file content.
  # Returns [fm_hash, body_text]. If there is no frontmatter block,
  # fm_hash is empty and body_text is the full content.
  # Dates and times are allowed. Invalid YAML is reported as an error,
  # and fm_hash is nil.
  #
  def parse_frontmatter( content, path )
    if content =~ /\A---\s*\n(.*?\n)---\s*\n?(.*)\z/m
      fm_text, body_text = $1, $2
      fm_hash = YAML.safe_load( fm_text, permitted_classes: [ Date, Time ] ) || {}
      return fm_hash, body_text if fm_hash.is_a?( Hash )

      return frontmatter_err( path, "it isn't a list of key: value pairs" )
    end

    return {}, content
  rescue Psych::SyntaxError => e
    return frontmatter_err( path, "it isn't valid YAML (#{e.problem})" )
  rescue Psych::Exception => e
    return frontmatter_err( path, "it couldn't be loaded (#{e.message})" )
  end

  #
  # Report frontmatter that can't be used, and return no hash or body.
  #
  def frontmatter_err( path, reason )
    @engine.err "Couldn't read the frontmatter in '#{path}': #{reason}."
    return nil, nil
  end

  #
  # Build the file content string from a frontmatter hash and body text.
  # Emits frontmatter as YAML between --- delimiters.
  #
  def build_content( fm_hash, body_text )
    if fm_hash.empty?
      return body_text
    end

    # Write times in UTC, as they were most likely written, not local time.
    fm_hash = fm_hash.transform_values { |v| v.is_a?( Time ) ? v.utc : v }

    # to_yaml emits "---\nkey: val\n"; strip the leading "---\n" and rewrap.
    fm_yaml = fm_hash.to_yaml.sub( /\A---\n/, '' )

    # to_yaml writes a UTC time as 2026-10-01 09:30:00.000000000 Z. A time
    # with no zone reads as UTC, so dropping the suffix keeps the same time.
    fm_yaml = fm_yaml.gsub( /(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d)\.0+ Z$/, '\1' )
    "---\n#{fm_yaml}---\n#{body_text}"
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
      :description => 'A Markdown file with YAML frontmatter. Holds a ' \
        'path to a .md file and exposes the frontmatter fields as ' \
        'dynamic string children under frontmatter, and the Markdown ' \
        'body as a text child under body. Use read to load a file into ' \
        'the object tree and write to serialize it back. Both ' \
        'frontmatter and body can be modified between a read and a write.',
      :children => [
        'path (file) — Path to the Markdown file.',
        'frontmatter (container) — Container whose children map to YAML frontmatter keys.',
        'body (text) — The Markdown body (everything after the --- closing delimiter).'
      ],
      :messages => [
        'read — Read the file at path, parse the YAML frontmatter and Markdown body. The frontmatter children are replaced with exactly the keys in the file (keys from an earlier read are removed); dates and times become text (times in UTC). Populates frontmatter.* children and body. It is true when the file was read, false if it could not be.',
        'write — Serialize frontmatter children back to YAML and combine with body. Writes the result to the file at path, creating it if it does not exist. Key order is preserved, and values that were not changed keep their YAML type (eg. a date or a number).'
      ],
      :notes => 'If the file has no frontmatter block, frontmatter ' \
        'will have no children and body will contain the full file ' \
        'content. These are errors, and read leaves the children as ' \
        'they were and puts false in it: an empty path, a file that ' \
        'does not exist or cannot be read, and frontmatter that is not ' \
        'valid YAML. An empty path or a failed write is also an error ' \
        'for write; write does not overwrite a file whose frontmatter ' \
        "is not valid YAML. Uses Ruby's built-in psych library for " \
        'YAML parsing — no additional dependencies.',
      :examples => <<~EXAMPLES.strip
        doc [md_doc] :
          path [file] : ~/notes/project.md
          frontmatter [can] :
          body [text] :

        on_load [script] :
          load lib md
          tell doc to read
          show doc.frontmatter.title
          show doc.body
      EXAMPLES
    }
  end

end
