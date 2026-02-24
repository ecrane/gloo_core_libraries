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

    @file_count = 0
    @test_count = 0
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
  #    Show Results
  # ---------------------------------------------------------------------

  #
  # Show the results.
  #
  def show_results
    delta = duration.round( 2 )
    puts
    puts get_result_summary.white
    puts "Tests finished in #{delta} seconds".white
    puts
  end

  # 
  # Get a textual summary of the results.
  #
  def get_result_summary
    return "Files: #{@file_count} Tests: #{@test_count} Passed: #{@pass_count} " + 
      "Failed: #{@fail_count} Assertions: #{@assert_count}"
  end

end
