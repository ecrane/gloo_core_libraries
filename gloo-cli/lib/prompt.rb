# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2019 Eric Crane.  All rights reserved.
#
# Show a CLI prompt and collect user input.
#

class Prompt < Gloo::Core::Obj

  KEYWORD = 'prompt'.freeze
  KEYWORD_SHORT = 'ask'.freeze
  PROMPT = 'prompt'.freeze
  RESULT = 'result'.freeze
  DEFAULT = 'default'.freeze
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
  # Get the default value.
  # This is an optional field.
  # If present, it starts the prompt with the default value.
  # Returns nil if there is none.
  #
  def default_value
    o = find_child DEFAULT
    return nil unless o

    return o.value
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
    fac.create_string RESULT, nil, self
  end


  # ---------------------------------------------------------------------
  #    Messages
  # ---------------------------------------------------------------------

  #
  # Get a list of message names that this object receives.
  #
  def self.messages
    return super + %w[run multiline]
  end

  #
  # Show a multiline prompt and get the user's input.
  #
  def msg_multiline
    prompt = prompt_value
    result = @engine.platform.prompt.multiline( prompt )
    set_result result.join
  end

  #
  # Show the prompt and get the user's input.
  #
  def msg_run
    prompt = prompt_value
    result = @engine.platform.prompt.ask( prompt, default_value )
    set_result result
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
      :description => 'CLI prompt for user input.',
      :children => [
        "prompt (string) — Default: '>'. The prompt displayed to the user; the default is used if there is no prompt child.",
        "result (string) — The result with the user's input."
      ],
      :messages => [
        'run — Prompt the user; the answer is put in result and in it.',
        'multiline — Show a multiline prompt; the answer is put in result and in it.'
      ],
      :examples => <<~EXAMPLES.strip
        ask [ask] :
          prompt [string] : What is your name?
          result [string] :
          on_load [script] :
            run ask
            show 'Hello, ' + ask.result + '!  Thanks for playing'
      EXAMPLES
    }
  end

end
