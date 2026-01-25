
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

#
# Load the version from the VERSION file.
#
def get_version
  f = File.dirname( File.absolute_path( __FILE__ ) )
  f = File.dirname( File.dirname( f ) )
  puts f + ' -------- '
  f = File.join( f, 'VERSION' )
  return File.read( f )
end


Gem::Specification.new do |spec|
  spec.name          = 'gloo-sqlite'
  spec.version       = get_version
  spec.authors       = ['Eric Crane']
  spec.email         = ['eric.crane@mac.com']

  spec.summary       = %q{Gloo core library. SQLite support.}
  spec.description   = %q{Adds SQLite support to Gloo.}
  spec.homepage      = "https://gloo.ecrane.us/"
  spec.license       = 'MIT'

  spec.metadata["gloo.type"] = "core-library"

  spec.files = [
    "lib/gloo-sqlite.rb",
    "lib/sqlite.rb"
  ]

  spec.require_paths = ['lib']

  spec.add_dependency 'sqlite3', '~> 1.4', '>= 1.4.2'
end
