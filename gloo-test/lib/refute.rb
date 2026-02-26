#
# Refute that [it] is true.
# (Assert that [it] is false.)
#
class Refute < Gloo::Core::Verb

  KEYWORD = 'refute'.freeze
  KEYWORD_SHORT = 'expect_not'.freeze
  DEFAULT_MESSAGE = 'Refutation failed'.freeze

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
      @engine.context_object.refute_count += 1
      if @engine.heap.it.is_false?
        # Refutation passes
        @engine.context_object.passed = true
        return true
      else
        # Refutation fails
        @engine.context_object.passed = false
        @engine.context_object.add_message(get_message)
        return false
      end
    rescue => ex
      @engine.log_exception ex
    end
  end

  #
  # Get the refutation message.
  #
  def get_message
    if @tokens.token_count > 1
      expr = Gloo::Expr::Expression.new( @engine, @tokens.params )
      result = expr.evaluate
      return result
    end
    return DEFAULT_MESSAGE
  end

end
