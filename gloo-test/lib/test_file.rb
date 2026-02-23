#
# A single Test File, might have multiple tests.
#
class TestFile

  #
  # Set up the test file.
  #
  def initialize( engine, path_name )
    @engine = engine
    @path_name = path_name

    @tests = []
  end

  #
  # Execute all tests in this file and report results.
  #
  def run
  end

  #
  # Get the number of tests run.
  #
  def tests_run
    return @tests.length
  end

end



