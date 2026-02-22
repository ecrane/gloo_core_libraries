#
# A gloo unit test results collection.
# The results of a the set of tests run.
#
class Results 

  #
  # Set up the results collection.
  #
  def initialize( engine )
    @engnine = engine
    
    puts "Results initialized"
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

end
