# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2020 Eric Crane.  All rights reserved.
#
# Markdown data.
#
require 'redcarpet'

class Md < Gloo::Core::Obj

  KEYWORD = 'markdown'.freeze
  KEYWORD_SHORT = 'md'.freeze

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

  #
  # Does this object support multi-line values?
  # Initially only true for scripts.
  #
  def multiline_value?
    return false
  end

  #
  # Get the number of lines of text.
  #
  def line_count
    return value.split( "\n" ).count
  end
  

  # ---------------------------------------------------------------------
  #    Messages
  # ---------------------------------------------------------------------

  #
  # Get a list of message names that this object receives.
  #
  def self.messages
    return super + %w[show render update_asset_path]
  end

  #
  # Show the markdown data in the terminal.
  #
  def msg_show
    @engine.platform.show self.value
  end

  #
  # Render the markdown as HTML.
  # Needs an optional parameter of where to put the rendered html.
  # The html will be in 'it' as well.
  #
  def msg_render
    html = MarkdownExt.render_extensions( value )
    html = Md.md_2_html( html )

    # Put the HTML in the optional parameter if one is given.
    if @params&.token_count&.positive?
      pn = Gloo::Core::Pn.new( @engine, @params.first )
      o = pn.resolve
      o.set_value html
    end

    # Put the HTML in it, in any case.
    @engine.heap.it.set_to html
  end

  # 
  # Update the asset path in the markdown.
  # Take out leading relative path so that path starts
  # at the asset root.
  # 
  def msg_update_asset_path
    data = self.value
    out_data = ""
    
    data.lines.each do |line|
      if line.include?( '![' ) && line.include?( '](') && line.include?( '/asset/')
        prefix = line[ 0, ( line.index( '](' ) + 2 ) ]
        suffix = line[ (line.index( '/asset/' )) .. -1 ]
        out_data << "#{prefix}#{suffix}"
      else
        out_data << line
      end
    end

    self.value = out_data
  end


  # ---------------------------------------------------------------------
  #    Static Helpers
  # ---------------------------------------------------------------------

  # 
  # Convert markdown to HTML using the
  # Redcarpet markdown processor.
  # 
  def self.md_2_html( md )
    markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML,
      autolink: true,
      fenced_code_blocks: true,
      tables: true,
      strikethrough: true )

    return markdown.render( md )
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
      :description => 'Markdown data in a text string. Also supports ' \
        'gloo Markdown extensions (panel, note, quote, idea and check ' \
        'blocks) rendered via MarkdownExt when the data is rendered.',
      :messages => [
        'show — Show the markdown data in the terminal.',
        'render ({dst}) — Convert the markdown to HTML and put it in the {dst} object. The HTML is also put into it either way.',
        'update_asset_path — Update asset paths for all images in the source markdown, so files can refer to images from a path different from the page using them.'
      ],
      :examples => <<~EXAMPLES.strip
        md [can] :
          f [file] :
          on_load [script] :
            put $.gloo.projects + "/o/data/txt.md" into md.f
            tell md.f to read (md.data)
            tell md.data to show
          data [md] :
      EXAMPLES
    }
  end

end
