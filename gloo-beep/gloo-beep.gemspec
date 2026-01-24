
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "gloo_beep"

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

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  # spec.bindir        = 'exe'
  # spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # spec.executables << 'o'
  # spec.executables << 'gloo'

  # spec.add_development_dependency 'bundler'
  # spec.add_development_dependency "rake", '~> 13.0', '>= 13.0.1'
  # spec.add_development_dependency 'concurrent-ruby', '1.3.4'

  # spec.add_dependency "activesupport", '~> 6.1', ">= 6.1.5" 
end
