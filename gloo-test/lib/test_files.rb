#
# The collection of Test Files.
#
class TestFiles

  TEST_FILE_PATTERN = '**/*.test.gloo'

  #
  # Set up the test file.
  #
  def initialize( engine, input_files = nil )
    @engnine = engine
    @input_files = input_files
    @files = []
  end

  #
  # Detect test files.
  #
  def detect_files
    puts "Detecting test files…"

    if @input_files.length > 0
      use_input_files
    else
      # Use the current directory
      look_for_files_in Dir.pwd
    end

    puts "Found #{count} test files"
  end

  # 
  # Use the files and or directories specified by the user.
  #
  def use_input_files
    puts "Input files specified: #{@input_files}"
    @input_files.each do |f| 
      puts "Test file specified: #{f}"
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
    puts "Looking for test files in: #{dir}"
    root = File.join( dir, TEST_FILE_PATTERN )
    files = Dir.glob( root )
    puts "Found files: #{@files}"
    files.each do |f| 
      puts "Test file: #{f}"
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
  # Get the number of test files.
  #
  def count
    return @files.length
  end

end



