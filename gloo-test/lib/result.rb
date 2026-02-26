#
# A gloo unit test result object.
# The result of a single test.
#
class Result

  attr_accessor :passed, :assert_count, :refute_count

  def initialize( engine, test )
    @engine = engine
    @test = test
    @test_desc = test.test_desc
    @pn = test.pn

    @assert_count = 0
    @refute_count = 0

    @passed = true
    @failure_msg = ''
  end

  #
  # Show the test result symbol.
  #
  def show_result_symbol
    print @passed ? '.' : 'x'
  end

  #
  # Add a failure message to the result.
  #
  def add_message(message)
    @failure_msg += "   " + message + "\n"
  end

  # 
  # Show the failure message.
  #
  def show_failure
    puts "#{@pn} -> #{@test_desc}"
    puts @failure_msg
    puts
  end
end
