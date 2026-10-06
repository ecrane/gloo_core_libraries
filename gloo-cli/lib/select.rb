# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2020 Eric Crane.  All rights reserved.
#
# Show a CLI prompt and user selection from a list.
#

class Select < Gloo::Core::Obj

  KEYWORD = 'select'.freeze
  KEYWORD_SHORT = 'sel'.freeze
  PROMPT = 'prompt'.freeze
  OPTIONS = 'options'.freeze
  RESULT = 'result'.freeze
  DEFAULT_PROMPT = '>'.freeze

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
  # Get the prompt from the child object.
  # The default prompt if there is none.
  #
  def prompt_value
    o = find_child PROMPT
    return o ? o.value : DEFAULT_PROMPT
  end

  #
  # Get the list of options for selection.
  #
  def options
    o = find_child OPTIONS
    return [] unless o

    return o.children.map( &:name )
  end

  #
  # Get the value of the selected item.
  #
  def key_for_option( selected )
    o = find_child OPTIONS
    return nil unless o

    o.children.each do |c|
      return c.value if c.name == selected
    end

    return nil
  end

  #
  # Set the result to the answer, and put it in it.
  # The answer is kept even if there is no result child.
  #
  def set_result( data )
    find_child( RESULT )&.set_value data
    @engine.heap.it.set_to data
  end

  # ---------------------------------------------------------------------
  #    Children
  # ---------------------------------------------------------------------

  #
  # Does this object have children to add when an object
  # is created in interactive mode?
  # This does not apply during obj load, etc.
  #
  def add_children_on_create?
    return true
  end

  #
  # Add children to this object.
  # This is used by containers to add children needed
  # for default configurations.
  #
  def add_default_children
    fac = @engine.factory
    fac.create_string PROMPT, DEFAULT_PROMPT, self
    fac.create_can OPTIONS, self
    fac.create_string RESULT, nil, self
  end

  # ---------------------------------------------------------------------
  #    Messages
  # ---------------------------------------------------------------------

  #
  # Get a list of message names that this object receives.
  #
  def self.messages
    return super + %w[run]
  end

  #
  # Show the prompt and get the user's selection.
  #
  def msg_run
    if options.empty?
      @engine.err "select '#{name}' has no options."
      @engine.heap.it.set_to false
      return
    end

    prompt = prompt_value
    # Page size was part of the tty-prompt but not used now.
    # per = Gloo::App::Settings.page_size( @engine )
    result = @engine.platform.prompt.select( prompt, options )
    set_result self.key_for_option( result )
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
      :description => 'Prompt for user to select from a list of options.',
      :children => [
        "prompt (string) — Default: '>'. The prompt displayed to the user; the default is used if there is no prompt child.",
        'options (container) — The list of options for the selection list. The name of each option is presented to the user, but the value is put in the result.',
        "result (string) — The result with the user's selection."
      ],
      :messages => [
        'run — Prompt the user for a selection; the chosen option\'s value is put in result and in it. It is an error if there are no options (it is false).'
      ],
      :examples => <<~EXAMPLES.strip
        select [select] :
          prompt [string] : What is your favorite color?
          options [can] :
            red : r
            green : g
            blue : b
          result [string] :
          on_load [script] :
            run select
            show select.result
      EXAMPLES
    }
  end

end
