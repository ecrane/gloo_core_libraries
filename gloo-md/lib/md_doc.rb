# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# A Markdown document with YAML frontmatter.
# Holds a file path and exposes the frontmatter fields as container
# children and the Markdown body as a text child.
#
require 'yaml'

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
  # Only scalar frontmatter values become gloo string children; complex values
  # (arrays, nested hashes) are skipped — they are preserved on write by
  # re-reading the file.
  #
  def msg_read
    path = resolve_path
    return unless path

    unless File.exist?( path )
      @engine.log.error "md_doc file not found: #{path}"
      return
    end

    content = File.read( path )
    fm_hash, body_text = parse_frontmatter( content )

    fm_can = find_child FRONTMATTER
    if fm_can && fm_hash
      fm_hash.each do |key, val|
        next unless scalar?( val )
        child = fm_can.find_add_child( key.to_s, 'string' )
        child.set_value val.to_s
      end
    end

    body = find_child BODY
    body.set_value( body_text ) if body
  end

  #
  # Serialize frontmatter and body children back to the file at path.
  # Re-reads the current file to get the base hash (preserving arrays and other
  # complex values), then overlays the scalar children which may have been
  # modified. Creates the file if it does not exist.
  #
  def msg_write
    path = resolve_path
    return unless path

    expanded = File.expand_path( path )

    # Re-read the file so arrays and nested hashes survive unchanged.
    base = {}
    if File.exist?( expanded )
      base, _ = parse_frontmatter( File.read( expanded ) )
    end

    fm_can = find_child FRONTMATTER

    # Overlay scalar children; updating an existing key preserves its position.
    if fm_can
      fm_can.children.each do |child|
        base[ child.name ] = child.value
      end
    end

    body = find_child BODY
    body_text = body ? body.value.to_s : ''

    File.write( expanded, build_content( base, body_text ) )
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
      val.is_a?( TrueClass ) || val.is_a?( FalseClass ) || val.nil?
  end

  #
  # Get the expanded path string from the path child.
  #
  def resolve_path
    o = find_child PATH
    return nil unless o
    return nil if o.value.to_s.strip.empty?

    File.expand_path( o.value.to_s )
  end

  #
  # Parse YAML frontmatter from file content.
  # Returns [fm_hash, body_text]. If there is no frontmatter block,
  # fm_hash is empty and body_text is the full content.
  #
  def parse_frontmatter( content )
    if content =~ /\A---\s*\n(.*?\n)---\s*\n?(.*)\z/m
      fm_hash   = YAML.safe_load( $1 ) || {}
      body_text = $2
      return fm_hash, body_text
    end

    return {}, content
  end

  #
  # Build the file content string from a frontmatter hash and body text.
  # Emits frontmatter as YAML between --- delimiters.
  #
  def build_content( fm_hash, body_text )
    if fm_hash.empty?
      return body_text
    end

    # to_yaml emits "---\nkey: val\n"; strip the leading "---\n" and rewrap.
    fm_yaml = fm_hash.to_yaml.sub( /\A---\n/, '' )
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
        'read — Read the file at path, parse the YAML frontmatter and Markdown body. Frontmatter children are created dynamically from whatever keys are present in the file. Populates frontmatter.* children and body.',
        'write — Serialize frontmatter children back to YAML and combine with body. Writes the result to the file at path, creating it if it does not exist. Key order is preserved; quoting style may normalize on first write, but semantic content is unchanged.'
      ],
      :notes => 'If the file has no frontmatter block, frontmatter ' \
        'will have no children and body will contain the full file ' \
        'content. If path is empty or the file does not exist, read ' \
        'logs an error and returns without modifying children. Uses ' \
        "Ruby's built-in psych library for YAML parsing — no " \
        'additional dependencies.',
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
