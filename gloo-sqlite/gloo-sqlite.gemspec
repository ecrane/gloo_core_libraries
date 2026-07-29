
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# Read the version from the VERSION file
version = File.read(File.expand_path("lib/VERSION", __dir__)).strip

Gem::Specification.new do |spec|
  spec.name          = 'gloo-sqlite'
  spec.version       = version
  spec.authors       = ['Eric Crane']
  spec.email         = ['eric.crane@mac.com']

  spec.summary       = %q{Gloo core library. SQLite support.}
  spec.description   = %q{Adds SQLite support to Gloo.}
  spec.homepage      = "https://gloo.ecrane.us/"
  spec.license       = 'MIT'

  spec.metadata["gloo.type"] = "core-library"
  spec.metadata["documentation_uri"] = "https://github.com/ecrane/gloo"

  spec.files = [
    "lib/gloo-sqlite.rb",
    "lib/sqlite.rb"
  ]

  spec.require_paths = ['lib']

  # 
  # Database specific dependencies
  # 
  spec.add_dependency 'sqlite3', '~> 1.4', '>= 1.4.2'
end
