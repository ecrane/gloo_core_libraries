#
# A gloo unit test result object.
# The result of a single test.
#
class Result

  EXPECTED_FAIL_MSG = 'expected this test to fail, but no assertion failed'.freeze

  attr_accessor :passed, :assert_count, :refute_count,
    :error_count, :warning_count, :expect_errors
  attr_reader :pn

  #
  # Set up the result for the given test.
  #
  def initialize( engine, test )
    @engine = engine
    @test = test
    @test_desc = test.test_desc
    @pn = test.pn

    @assert_count = 0
    @refute_count = 0

    # Errors and warnings logged while the test ran, and whether
    # the test declared that it triggers them on purpose.
    @error_count = 0
    @warning_count = 0
    @expect_errors = false

    @passed = true
    @failure_msg = ''
  end

  #
  # Did the test log errors or warnings it didn't declare?
  #
  def unexpected_logs?
    return false if @expect_errors

    return ( @error_count + @warning_count ).positive?
  end

  #
  # The test was meant to fail: it passes if an assertion failed,
  # and fails if no assertion failed.
  #
  def expect_failure
    if @passed
      @passed = false
      add_message EXPECTED_FAIL_MSG
    else
      @passed = true
    end
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
