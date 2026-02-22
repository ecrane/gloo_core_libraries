#
# Test Runner.
#
class TestRunner < Gloo::Core::Verb


  #
  # Set up the test runner.
  #
  def initialize( engine )
    @engnine = engine

    @files = TestFiles.new( engine )
    @results = Results.new( engine )

    puts "TestRunner initialized"
  end

  #
  # Execute all tests and display results.
  #
  def run
    puts "TestRunner is running…"
    
    # Get a list of test files
    puts "Getting test files…"
    @files.detect_files

    # Randomize the list
    puts "Randomizing test files…"

    puts "Starting timer…"
    @results.start_timer
    
    # For each test file
      # Load the test file
      # Run all tests in the file
      # Collect the results
      # Add the results to the overall results
      # Reset the engine

    # Show final results
    @results.end_timer
    puts "TestRunner finished in #{@results.duration} seconds"
  end

end



