#
# Assert that [it] is true.
#
class Assert < Gloo::Core::Verb

  KEYWORD = 'assert'.freeze
  KEYWORD_SHORT = 'expect'.freeze

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
      if @engine.heap.it.true?
        # Assertion passes
        return true
      else
        # Assertion fails
        return false
      end
    rescue => ex
      @engine.log_exception ex
    end
  end

end
