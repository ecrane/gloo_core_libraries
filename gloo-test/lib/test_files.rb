#
# The collection of Test Files.
#
class TestFiles

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
    # TODO: Detect test files
    puts "Detecting test files…"

    if @input_files
      @input_files.each { |f| puts "Test file specified: #{f}" }
    else
      puts "No test files specified, looking in current folder…"
      dir = Dir.pwd
      puts "Current directory: #{dir}"
      files = dir.glob("*.test.gloo")
      puts "Found files: #{files}"
    end


    puts "Found #{@files.count} test files"
  end
  
  #
  # Add a test file to the collection.
  #
  def add( file )
    @files << file
  end

  # 
  # Get the number of test files.
  #
  def count
    return @files.length
  end

end



