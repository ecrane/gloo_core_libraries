#
# Test Runner.
#
class TestRunner < Gloo::Core::Verb


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

    @results.show_results
    @engine.log.debug "TestRunner is finished"
  end

  # 
  # Set up the test runner.
  #
  def setup
    @engine.log.debug "TestRunner is running…"
    puts
    puts "Gloo Test Runner".white
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
  #
  def run_one_file( file )
    print '.'
    # file.show_info

    # Load the test file
    # Run all tests in the file
    # Collect the results
    # Add the results to the overall results
    # Reset the engine
  end
end



