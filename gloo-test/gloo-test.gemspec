
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# Read the version from the VERSION file
version = File.read(File.expand_path("lib/VERSION", __dir__)).strip

Gem::Specification.new do |spec|
  spec.name          = 'gloo-test'
  spec.version       = version
  spec.authors       = ['Eric Crane']
  spec.email         = ['eric.crane@mac.com']

  spec.summary       = %q{Gloo core library. Gloo Unit Test support.}
  spec.description   = %q{Adds Gloo Unit Test support to Gloo.}
  spec.homepage      = "https://github.com/ecrane/gloo"
  spec.license       = 'MIT'

  spec.metadata["gloo.type"] = "core-library"
  spec.metadata["documentation_uri"] = "https://github.com/ecrane/gloo"

  spec.files = [
    "lib/assert.rb",
    "lib/gloo-test.rb",
    "lib/refute.rb",
    "lib/result.rb",
    "lib/results.rb",
    "lib/test_file.rb",
    "lib/test_files.rb",
    "lib/test_runner.rb",
    "lib/test.rb"
  ]

  spec.require_paths = ['lib']
end
