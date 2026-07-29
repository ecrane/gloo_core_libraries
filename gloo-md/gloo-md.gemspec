
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# Read the version from the VERSION file
version = File.read(File.expand_path("lib/VERSION", __dir__)).strip

Gem::Specification.new do |spec|
  spec.name          = 'gloo-md'
  spec.version       = version
  spec.authors       = ['Eric Crane']
  spec.email         = ['eric.crane@mac.com']

  spec.summary       = %q{Gloo core library. Markdown support.}
  spec.description   = %q{Adds Markdown support to Gloo.}
  spec.homepage      = "https://github.com/ecrane/gloo"
  spec.license       = 'MIT'

  spec.metadata["gloo.type"] = "core-library"
  spec.metadata["documentation_uri"] = "https://github.com/ecrane/gloo"

  spec.files = [
    "lib/gloo-md.rb",
    "lib/md.rb",
    "lib/md_doc.rb",
    "lib/markdown_ext.rb"
  ]

  spec.require_paths = ['lib']

  # 
  # Used for markdown rendering
  # 
  spec.add_dependency 'redcarpet', '~> 3.6.0'
end
