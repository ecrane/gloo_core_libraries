#
# Test Runner.
#
class TestRunner


  #
  # Set up the test runner.
  #
  def initialize( engine, input_files = nil )
    @engine = engine

    @files = TestFiles.new( @engine, input_files )
    @results = Results.new( @engine )

    @engine.log.debug "TestRunner initialized"
  end

  #
  # Execute all tests and display results.
  #
  def run
    setup

    @results.start_timer    
    run_for_files
    @results.end_timer

    @results.show_failures
    @results.show_results
    @engine.log.debug "TestRunner is finished"
  end

  # 
  # Set up the test runner.
  #
  def setup
    @engine.log.debug "TestRunner is running…"
    puts
    puts @engine.theme.emphasis( "Gloo Test Runner" )
    puts

    # Get a list of test files and randomize
    @files.detect_files
    @results.file_count = @files.count
    @files.randomize
  end

  #
  # Run tests for each file.
  #
  def run_for_files
    @files.each do |file|
      run_one_file( file )
    end
    puts
  end

  #
  # Run tests for a single file.
  # Once done, reset the engine's state.
  #
  def run_one_file( file )
    # Run all tests in the file
    # Add the results to the overall results
    file.run_tests( @results )

    # Reset the engine's state
    @engine.reset_state
  end
end



