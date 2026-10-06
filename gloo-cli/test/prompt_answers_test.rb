# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# The answers from confirm, prompt and select: they go in it and in
# result. The platform prompt is faked, so nothing waits for input.
#
require 'test_helper'

#
# Stands in for the platform's prompt, giving canned answers and
# remembering the prompt it was shown.
#
class FakePrompt

  attr_reader :shown

  #
  # Give the given answer to every question.
  #
  def initialize( answer )
    @answer = answer
  end

  #
  # A yes/no question.
  #
  def yes?( prompt )
    @shown = prompt
    return @answer
  end

  #
  # A question with a typed answer.
  #
  def ask( prompt, default = nil )
    @shown = prompt
    return @answer
  end

  #
  # A question with a multi-line answer, as lines.
  #
  def multiline( prompt )
    @shown = prompt
    return @answer
  end

  #
  # Choose one of the options.
  #
  def select( prompt, options )
    @shown = prompt
    return @answer
  end

end

class PromptAnswersTest < BaseEngineTest

  #
  # Run a line of gloo.
  #
  def run_cmd( cmd )
    @engine.parser.parse_immediate( cmd ).run
  end

  #
  # Answer every prompt with the given answer; returns the fake.
  #
  def answer_with( answer )
    fake = FakePrompt.new( answer )
    @engine.platform.define_singleton_method( :prompt ) { fake }
    return fake
  end

  #
  # The value of the object at the path.
  #
  def value_of( pn )
    return Gloo::Core::Pn.new( @engine, pn ).resolve.value
  end

  #
  # confirm puts the answer in it and in result.
  #
  def test_confirm_answer_in_it_and_result
    answer_with( true )
    run_cmd 'create c as confirm'
    run_cmd 'tell c to run'

    assert_equal true, @engine.heap.it.value
    assert_equal true, value_of( 'c.result' )
  end

  #
  # confirm 'no' is false in it.
  #
  def test_confirm_no_is_false
    answer_with( false )
    run_cmd 'create c as confirm'
    run_cmd 'tell c to run'

    assert_equal false, @engine.heap.it.value
  end

  #
  # prompt puts the typed text in it and in result.
  #
  def test_prompt_answer_in_it_and_result
    answer_with( 'Eric' )
    run_cmd 'create p as prompt'
    run_cmd 'tell p to run'

    assert_equal 'Eric', @engine.heap.it.value
    assert_equal 'Eric', value_of( 'p.result' )
  end

  #
  # prompt multiline puts the joined lines in it.
  #
  def test_prompt_multiline_answer_in_it
    answer_with( [ "one\n", "two\n" ] )
    run_cmd 'create p as prompt'
    run_cmd 'tell p to multiline'

    assert_equal "one\ntwo\n", @engine.heap.it.value
  end

  #
  # select puts the chosen option's value in it and in result.
  #
  def test_select_answer_in_it_and_result
    answer_with( 'green' )
    run_cmd 'create s as select'
    run_cmd 'create s.options.red as string : r'
    run_cmd 'create s.options.green as string : g'
    run_cmd 'tell s to run'

    assert_equal 'g', @engine.heap.it.value
    assert_equal 'g', value_of( 's.result' )
  end

  #
  # select with no options is an error, and it is false.
  #
  def test_select_with_no_options
    fake = answer_with( 'green' )
    run_cmd 'create s as select'
    run_cmd 'tell s to run'

    assert_equal false, @engine.heap.it.value
    assert_equal "select 's' has no options.", @engine.heap.error.value
    assert_nil fake.shown
  end

  #
  # Without a prompt child, the default prompt is shown.
  #
  def test_default_prompt_without_a_prompt_child
    fake = answer_with( true )
    run_cmd 'create c as can'
    run_cmd 'create c.ok as confirm'
    run_cmd 'tell c.ok to run'
    assert_equal CliConfirm::DEFAULT_PROMPT, fake.shown

    obj = Gloo::Core::Pn.new( @engine, 'c.ok' ).resolve
    obj.remove_child( obj.find_child( 'prompt' ) )
    run_cmd 'tell c.ok to run'
    assert_equal CliConfirm::DEFAULT_PROMPT, fake.shown
  end

  #
  # Without a result child, the answer is still in it.
  #
  def test_answer_in_it_without_a_result_child
    answer_with( 'Eric' )
    run_cmd 'create p as prompt'
    obj = Gloo::Core::Pn.new( @engine, 'p' ).resolve
    obj.remove_child( obj.find_child( 'result' ) )

    run_cmd 'tell p to run'
    assert_equal 'Eric', @engine.heap.it.value
  end

end
