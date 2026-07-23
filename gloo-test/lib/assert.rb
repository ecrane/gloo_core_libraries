#
# Assert that [it] is true.
#
class Assert < Gloo::Core::Verb

  KEYWORD = 'assert'.freeze
  KEYWORD_SHORT = 'expect'.freeze
  DEFAULT_MESSAGE = 'Assertion failed'.freeze
  
  #
  # Get the Verb's keyword.
  #
  def self.keyword
    return KEYWORD
  end

  #
  # Get the Verb's keyword shortcut.
  #
  def self.keyword_shortcut
    return KEYWORD_SHORT
  end

  #
  # Run the verb.
  #
  def run
    begin
      @engine.context_object.assert_count += 1
      if @engine.heap.it.is_true?
        # Assertion passes
        @engine.context_object.passed = true
        return true
      else
        # Assertion fails
        @engine.context_object.passed = false
        @engine.context_object.add_message get_message
        return false
      end
    rescue => ex
      @engine.log_exception ex
    end
  end

  #
  # Get the assertion message.
  #
  def get_message
    if @tokens.token_count > 1
      expr = Gloo::Expr::Expression.new( @engine, @tokens.params )
      result = expr.evaluate
      return result
    end
    return DEFAULT_MESSAGE
  end

  # ---------------------------------------------------------------------
  #    Verb Documentation
  # ---------------------------------------------------------------------

  #
  # Get the verb's documentation data.
  #
  def self.doc_data
    {
      :name => KEYWORD,
      :shortcut => KEYWORD_SHORT,
      :description => 'Assert an expectation about the state or ' \
        'results. The verb looks at the value of it. If it is true, ' \
        'then the assertion passes, otherwise it fails.',
      :syntax => [ 'assert {optional expectation message}' ],
      :parameters => [
        "optional expectation message — A textual statement about " \
          "what was expected. Optional. If none provided the default " \
          "\"#{DEFAULT_MESSAGE}\" will be shown."
      ],
      :result => 'Validates an assumption and reports failures (or success).',
      :examples => <<~EXAMPLES.strip
        assert_noop [test] :
          description [string] : Assert no operation
          on_test [script] :
            noop
            assert 'noop should be true'
      EXAMPLES
    }
  end

end
