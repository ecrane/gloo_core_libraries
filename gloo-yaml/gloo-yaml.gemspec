lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

version = File.read(File.expand_path("lib/VERSION", __dir__)).strip

Gem::Specification.new do |spec|
  spec.name          = 'gloo-yaml'
  spec.version       = version
  spec.authors       = ['Eric Crane']
  spec.email         = ['eric.crane@mac.com']

  spec.summary       = %q{Gloo core library. YAML file support.}
  spec.description   = %q{Adds YAML file read/write support to Gloo.}
  spec.homepage      = "https://github.com/ecrane/gloo"
  spec.license       = 'MIT'

  spec.metadata["gloo.type"] = "core-library"
  spec.metadata["documentation_uri"] = "https://github.com/ecrane/gloo"

  spec.files = [
    "lib/gloo-yaml.rb",
    "lib/yaml_obj.rb"
  ]

  spec.require_paths = ['lib']
end
