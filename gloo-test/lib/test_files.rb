#
# The collection of Test Files.
#
class TestFiles
  include Enumerable

  TEST_FILE_PATTERN = '**/*.test.gloo'

  #
  # Set up the test file.
  #
  def initialize( engine, input_files = nil )
    @engine = engine
    @input_files = input_files
    @files = []
  end

  #
  # Detect test files.
  #
  def detect_files
    @engine.log.debug "Detecting test files…"

    if @input_files.length > 0
      use_input_files
    else
      # Use the current directory
      look_for_files_in Dir.pwd
    end

    @engine.log.debug "Found #{count} test files"
  end

  # 
  # Use the files and or directories specified by the user.
  #
  def use_input_files
    @engine.log.debug "Input files specified: #{@input_files}"
    @input_files.each do |f| 
      @engine.log.debug "Test file specified: #{f}"
      if Dir.exist?( f )
        # Expand path for file
        f = File.expand_path( f )
        look_for_files_in f
      elsif File.exist?( f )
        add( f )
      else
        # TODO: Show error
        puts "Test file does not exist: #{f}"
      end
    end
  end

  #
  # Look for test files in a directory.
  # The directory might be provided as a parameter to the test runner,
  # or if no parameter is provided, it is the current directory.
  #
  def look_for_files_in dir
    @engine.log.debug "Looking for test files in: #{dir}"
    root = File.join( dir, TEST_FILE_PATTERN )
    files = Dir.glob( root )
    @engine.log.debug "Found files: #{@files}"
    files.each do |f| 
      @engine.log.debug "Found: #{f}"
      add f
    end
  end
  
  #
  # Add a test file to the collection.
  #
  def add( file )
    @files << TestFile.new( @engine, file )
  end

  # 
  # Randomize the order of the test files.
  #
  def randomize
    @engine.log.debug "Randomizing test files…"
    @files.shuffle!
  end

  # 
  # Get the number of test files.
  #
  def count
    return @files.length
  end

  #
  # Iterator method for Enumerable interface.
  #
  def each(&block)
    @files.each(&block)
  end

end



