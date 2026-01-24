
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'gloo-beep'
  spec.version       = '1.0'
  spec.authors       = ['Eric Crane']
  spec.email         = ['eric.crane@mac.com']

  spec.summary       = %q{Gloo core library. A simple test library with a beep verb.}
  spec.description   = %q{A simple test library with a beep verb.}
  spec.homepage      = "https://gloo.ecrane.us/"
  spec.license       = 'MIT'

  spec.metadata["gloo.type"] = "core-library"

  spec.files = [
    "lib/gloo-beep.rb",
    "lib/gloo_beep.rb",
    "lib/beep.rb"
  ]

  # spec.bindir        = 'exe'
  # spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
