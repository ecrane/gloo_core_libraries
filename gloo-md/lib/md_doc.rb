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
  # Frontmatter children are created dynamically from whatever keys are present.
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
        child = fm_can.find_add_child( key.to_s, 'string' )
        child.set_value val.to_s
      end
    end

    body = find_child BODY
    body.set_value( body_text ) if body
  end

  #
  # Serialize frontmatter and body children back to the file at path.
  # Creates the file if it does not exist.
  #
  def msg_write
    path = resolve_path
    return unless path

    fm_can = find_child FRONTMATTER
    fm_hash = {}
    if fm_can
      fm_can.children.each do |child|
        fm_hash[ child.name ] = child.value
      end
    end

    body = find_child BODY
    body_text = body ? body.value.to_s : ''

    content = build_content( fm_hash, body_text )
    File.write( File.expand_path( path ), content )
  end


  # ---------------------------------------------------------------------
  #    Private helpers
  # ---------------------------------------------------------------------

  private

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

end
