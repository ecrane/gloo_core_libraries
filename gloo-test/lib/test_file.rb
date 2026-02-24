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
  # Execute all tests in this file and add results
  # to the overall test results.
  #
  def run_tests( results )
    # Load the test file
    @engine.persist_man.load( @path_name )
    # @engine.parser.run '.'

    # Find all Test objects in the loaded file(s)
    # The loaded file might have loaded other files

    # For each Test object, run its on_test script

    # Collect results from each test

    # Aggregate result from test into overall results

    print '.'
    # file.show_info
  end

  #
  # Get the number of tests run.
  #
  def tests_run_count
    return @tests.length
  end

  def show_info
    puts "Test file: #{@path_name}"
  end

end



