#
# A gloo unit test results collection.
# The results of a the set of tests run.
#
class Results 

  attr_accessor :file_count, :test_count, 
    :pass_count, :fail_count, :assert_count
  
  #
  # Set up the results collection.
  #
  def initialize( engine )
    @engine = engine

    @all_results = []
    @failures = []

    @file_count = 0
    @pass_count = 0
    @fail_count = 0
    @assert_count = 0
    
    @engine.log.debug "Results initialized"
  end

  # ---------------------------------------------------------------------
  #    Timer
  # ---------------------------------------------------------------------

  # 
  # Set a timer to track test duration.
  # 
  def start_timer
    @start_time = Time.now
  end

  # 
  # End the timer.
  # 
  def end_timer
    @end_time = Time.now
  end

  # 
  # Get the duration of the test.
  # 
  def duration
    return @end_time - @start_time
  end


  # ---------------------------------------------------------------------
  #    Results
  # ---------------------------------------------------------------------

  # 
  # Add a result to the collection.
  #
  def add_result( result )
    @all_results << result
    @failures << result unless result.passed

    @pass_count += 1 if result.passed
    @fail_count += 1 unless result.passed
    @assert_count += result.assert_count
    @assert_count += result.refute_count
  end


  # ---------------------------------------------------------------------
  #    Show Results
  # ---------------------------------------------------------------------

  #
  # Show the results.
  #
  def show_results
    delta = duration.round( 2 )
    puts
    puts get_result_summary
    puts "Tests finished in #{delta} seconds".white
    puts
  end

  #
  # Show the failures.
  #
  def show_failures
    if @fail_count > 0
      puts
      puts "*** Failures (#{@fail_count}) ***".red
      puts
      @failures.each do |failure|
        failure.show_failure
      end
    end
  end
  
  # 
  # Get a textual summary of the results.
  #
  def get_result_summary
    str = "Tests: #{@all_results.length} • Passed: #{@pass_count} • ".white
    if @fail_count > 0
      str += " Failed: #{@fail_count} ".red
    else
      str += " Failed: #{@fail_count} ".white
    end
    str += "\n  Assertions: #{@assert_count} • Files: #{@file_count}".yellow
    return str
  end

end
