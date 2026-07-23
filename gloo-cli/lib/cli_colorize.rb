# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2020 Eric Crane.  All rights reserved.
#
# Show colorized output.
#
require 'colorized_string'

class CliColorize < Gloo::Core::Obj

  KEYWORD = 'colorize'.freeze
  KEYWORD_SHORT = 'color'.freeze

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

  # ---------------------------------------------------------------------
  #    Children
  # ---------------------------------------------------------------------

  # Does this object have children to add when an object
  # is created in interactive mode?
  # This does not apply during obj load, etc.
  def add_children_on_create?
    return true
  end

  # Add children to this object.
  # This is used by containers to add children needed
  # for default configurations.
  def add_default_children
    fac = @engine.factory
    fac.create_string 'white', '', self
  end

  # ---------------------------------------------------------------------
  #    Messages
  # ---------------------------------------------------------------------

  #
  # Get a list of message names that this object receives.
  #
  def self.messages
    return super + [ 'run' ]
  end

  #
  # Run the colorize command.
  #
  def msg_run
    msg = ''
    children.each do |o|
      msg += ColorizedString[ o.value_display ].colorize( o.name.to_sym )
    end
    @engine.log.show msg
    @engine.heap.it.set_to msg.to_s
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
      :description => 'The Colorize object can be used to write output ' \
        'in color. The Colorize container can contain multiple ' \
        'strings, each one can have a different color as specified by ' \
        'the names of the children.',
      :children => [
        '[color] (string) — The name of the child or children is the color. The string\'s value is what will be written out.'
      ],
      :messages => [
        'run — Output the string in the color specified.'
      ],
      :examples => <<~EXAMPLES.strip
        color [can] :
          w [colorize] :
            white [string] : This is white!
          m [colorize] :
            red [string] : red -
            green [string] : green -
            blue [string] : blue
          on_load [script] :
            run color.w
            run color.m
      EXAMPLES
    }
  end

end
