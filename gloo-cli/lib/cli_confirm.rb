# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2019 Eric Crane.  All rights reserved.
#
# Show a CLI confirmation prompt.
#

class CliConfirm < Gloo::Core::Obj

  KEYWORD = 'confirm'.freeze
  KEYWORD_SHORT = 'confirm'.freeze
  PROMPT = 'prompt'.freeze
  DEFAULT_PROMPT = '> '.freeze
  RESULT = 'result'.freeze

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
    fac.create_string PROMPT, DEFAULT_PROMPT, self
    fac.create_bool RESULT, nil, self
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
  # Run the confirmation command.
  #
  def msg_run
    prompt = prompt_value
    result = @engine.platform.prompt.yes?( prompt )
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
      :description => 'CLI confirmation prompt.',
      :children => [
        "prompt (string) — Default: '> '. The confirmation prompt; the default is used if there is no prompt child.",
        'result (boolean) — The result of the prompt.'
      ],
      :messages => [
        'run — Prompt the user; the answer (true or false) is put in result and in it.'
      ],
      :examples => <<~EXAMPLES.strip
        confirm [confirm] :
          prompt [string] : Are you sure?
          result [boolean] :
          on_load [script] :
            run confirm
            show 'Confirmed: ' + confirm.result
      EXAMPLES
    }
  end

end
