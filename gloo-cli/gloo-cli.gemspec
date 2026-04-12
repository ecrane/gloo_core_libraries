
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# Read the version from the VERSION file
version = File.read(File.expand_path("lib/VERSION", __dir__)).strip

Gem::Specification.new do |spec|
  spec.name          = 'gloo-cli'
  spec.version       = version
  spec.authors       = ['Eric Crane']
  spec.email         = ['eric.crane@mac.com']

  spec.summary       = %q{Gloo core library. CLI support.}
  spec.description   = %q{Adds CLI support to Gloo.}
  spec.homepage      = "https://gloo.ecrane.us/"
  spec.license       = 'MIT'

  spec.metadata["gloo.type"] = "core-library"

  spec.files = [
    "lib/gloo-cli.rb",
    "lib/cli_colorize.rb",
    "lib/cli_confirm.rb",
    "lib/menu.rb",
    "lib/menu_item.rb",
    "lib/prompt.rb",
    "lib/shell_runner.rb",
    "lib/shell.rb",
    "lib/shell_context.rb",
    "lib/command_node.rb",
    "lib/select.rb"
  ]

  spec.require_paths = ['lib']
end
