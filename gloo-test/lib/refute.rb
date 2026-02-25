#
# Refute that [it] is true.
# (Assert that [it] is false.)
#
class Refute < Gloo::Core::Verb

  KEYWORD = 'refute'.freeze
  KEYWORD_SHORT = 'expect_not'.freeze

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
        return false
      end
    rescue => ex
      @engine.log_exception ex
    end
  end

end
