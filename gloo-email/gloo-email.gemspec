
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# Read the version from the VERSION file
version = File.read(File.expand_path("lib/VERSION", __dir__)).strip

Gem::Specification.new do |spec|
  spec.name          = 'gloo-email'
  spec.version       = version
  spec.authors       = ['Eric Crane']
  spec.email         = ['eric.crane@mac.com']

  spec.summary       = %q{Gloo core library. Gloo Email support.}
  spec.description   = %q{Adds Gloo Email support to Gloo.}
  spec.homepage      = "https://gloo.ecrane.us/"
  spec.license       = 'MIT'

  spec.metadata["gloo.type"] = "core-library"
  spec.metadata["documentation_uri"] = "https://github.com/ecrane/gloo"

  spec.files = [
    "lib/email_smtp.rb",
    "lib/email_imap.rb",
    "lib/email_msg.rb",
    "lib/gloo-email.rb",
    "lib/msg.rb",
    "lib/config.rb",
    "lib/smtp.rb"
  ]

  spec.require_paths = ['lib']
end
