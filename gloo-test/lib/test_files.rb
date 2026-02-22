#
# The collection of Test Files.
#
class TestFiles

  #
  # Set up the test file.
  #
  def initialize( engine )
    @engnine = engine
    @files = []
  end

  #
  # Detect test files.
  #
  def detect_files
    # TODO: Detect test files
    puts "Detecting test files…"

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



