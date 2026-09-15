
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
  spec.homepage      = "https://github.com/ecrane/gloo"
  spec.license       = 'MIT'

  spec.metadata["gloo.type"] = "core-library"
  spec.metadata["documentation_uri"] = "https://github.com/ecrane/gloo"

  spec.files = [
    "README.md",
    "lib/email_smtp.rb",
    "lib/email_imap.rb",
    "lib/email_msg.rb",
    "lib/gloo-email.rb",
    "lib/msg.rb",
    "lib/config.rb",
    "lib/smtp.rb"
  ]

  spec.require_paths = ['lib']

  #
  # Used for building/sending mail (Msg#get_mail, Smtp#send) and IMAP
  # message parsing (EmailImap#process_message). Was never declared
  # here even though lib/ already requires it directly - only worked
  # because it happened to be installed as a side effect of something
  # else.
  #
  spec.add_dependency 'mail'

  #
  # Development Dependencies
  #
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'minitest', '~> 5.1', '>= 5.14.2'
  spec.add_development_dependency 'rake', '~> 13.0', '>= 13.0.1'
end
