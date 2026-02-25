#
# A gloo unit test result object.
# The result of a single test.
#
class Result

  attr_accessor :passed, :failure_msg, :assert_count, :refute_count

  def initialize( engine, test )
    @engine = engine
    @test = test
    @test_name = test.test_name
    @test_expects = test.test_expects

    @assert_count = 0
    @refute_count = 0

    @passed = true
    @failure_msg = nil
  end

  #
  # Show the test result symbol.
  #
  def show_result_symbol
    print @passed ? '.' : 'X'
  end
end
