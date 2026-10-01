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
    theme = @engine.theme
    delta = duration.round( 2 )
    puts
    puts get_result_summary
    logged = get_logged_summary
    puts theme.warn( logged ) if logged
    puts theme.emphasis( "Tests finished in #{delta} seconds" )
    puts
  end

  #
  # Show the failures.
  #
  def show_failures
    if @fail_count > 0
      theme = @engine.theme
      puts
      puts theme.error( "*** Failures (#{@fail_count}) ***" )
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
    theme = @engine.theme
    str = theme.emphasis( "Tests: #{@all_results.length} • Passed: #{@pass_count} • " )
    if @fail_count > 0
      str += theme.error( " Failed: #{@fail_count} " )
    else
      str += theme.emphasis( " Failed: #{@fail_count} " )
    end
    str += theme.accent( "\n  Assertions: #{@assert_count} • Files: #{@file_count}" )
    return str
  end

  # ---------------------------------------------------------------------
  #    Logged Errors and Warnings
  # ---------------------------------------------------------------------

  #
  # Get a summary of the errors and warnings logged during the run
  # that no test declared (with expect_errors), naming the tests that
  # logged them. Returns nil when there's nothing unexpected.
  # Counts are since the log's counts were last reset (the runner
  # resets them just before running the tests).
  #
  def get_logged_summary
    unexpected = @all_results.select( &:unexpected_logs? )
    outside_errors, outside_warnings = logged_outside_tests

    errors = unexpected.sum( &:error_count ) + outside_errors
    warnings = unexpected.sum( &:warning_count ) + outside_warnings
    return nil if ( errors + warnings ).zero?

    lines = [ "  #{count_phrase( errors, warnings )} logged during the run; see #{log_path}" ]
    unexpected.each do |r|
      lines << "    #{r.pn} (#{count_phrase( r.error_count, r.warning_count )})"
    end
    if ( outside_errors + outside_warnings ).positive?
      lines << "    (outside tests: #{count_phrase( outside_errors, outside_warnings )})"
    end
    return lines.join( "\n" )
  end

  #
  # Get the errors and warnings logged outside any test (eg. while
  # loading a test file): everything logged less what the tests logged.
  #
  def logged_outside_tests
    log = @engine.log
    errors = log.error_count - @all_results.sum( &:error_count )
    warnings = log.warning_count - @all_results.sum( &:warning_count )
    return [ errors, warnings ]
  end

  #
  # Describe a count of errors and warnings, eg. "1 error",
  # "2 warnings", or "2 errors and 1 warning". Zero counts are left out.
  #
  def count_phrase( errors, warnings )
    parts = []
    parts << pluralize( errors, 'error' ) if errors.positive?
    parts << pluralize( warnings, 'warning' ) if warnings.positive?
    return parts.join( ' and ' )
  end

  #
  # A count with its noun, plural unless the count is one.
  #
  def pluralize( count, noun )
    return count == 1 ? "1 #{noun}" : "#{count} #{noun}s"
  end

  #
  # The error log's path, with the home folder shown as ~.
  #
  def log_path
    return @engine.log.err_file.sub( /\A#{Regexp.escape( Dir.home )}/, '~' )
  end

end
