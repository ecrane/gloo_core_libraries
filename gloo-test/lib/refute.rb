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
      if @engine.heap.it.false?
        # Refutation passes
        return true
      else
        # Refutation fails
        return false
      end
    rescue => ex
      @engine.log_exception ex
    end
  end

end
