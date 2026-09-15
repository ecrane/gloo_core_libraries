
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'gloo-beep'
  spec.version       = '1.0'
  spec.authors       = ['Eric Crane']
  spec.email         = ['eric.crane@mac.com']

  spec.summary       = %q{Gloo core library. A simple test library with a beep verb.}
  spec.description   = %q{A simple test library with a beep verb.}
  spec.homepage      = "https://github.com/ecrane/gloo"
  spec.license       = 'MIT'

  spec.metadata["gloo.type"] = "core-library"
  spec.metadata["documentation_uri"] = "https://github.com/ecrane/gloo"

  spec.files = [
    "README.md",
    "lib/gloo-beep.rb",
    "lib/beep.rb"
  ]

  spec.require_paths = ['lib']

  #
  # Development Dependencies
  #
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'minitest', '~> 5.1', '>= 5.14.2'
  spec.add_development_dependency 'rake', '~> 13.0', '>= 13.0.1'
end
