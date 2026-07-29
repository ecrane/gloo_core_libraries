
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# Read the version from the VERSION file
version = File.read(File.expand_path("lib/VERSION", __dir__)).strip

Gem::Specification.new do |spec|
  spec.name          = 'gloo-web'
  spec.version       = version
  spec.authors       = ['Eric Crane']
  spec.email         = ['eric.crane@mac.com']

  spec.summary       = %q{Gloo core library. Web Server and framework.}
  spec.description   = %q{Adds Web server and framework to Gloo.}
  spec.homepage      = "https://github.com/ecrane/gloo"
  spec.license       = 'MIT'

  spec.metadata["gloo.type"] = "core-library"
  spec.metadata["documentation_uri"] = "https://github.com/ecrane/gloo"

  spec.files = [
    "lib/gloo-web.rb",
    "lib/objs/element.rb",
    "lib/objs/field.rb",
    "lib/objs/form.rb",
    "lib/objs/page.rb",
    "lib/objs/partial.rb",
    "lib/objs/svr.rb",

    "lib/routing/show_routes.rb",
    "lib/routing/resource_router.rb",
    "lib/routing/router.rb",

    "lib/web_svr/asset_info.rb",
    "lib/web_svr/asset.rb",
    "lib/web_svr/config.rb",
    "lib/web_svr/embedded_renderer.rb",
    "lib/web_svr/handler.rb",
    "lib/web_svr/request_params.rb",
    "lib/web_svr/request.rb",
    "lib/web_svr/response_code.rb",
    "lib/web_svr/response.rb",
    "lib/web_svr/server.rb",
    "lib/web_svr/session.rb",
    "lib/web_svr/table_renderer.rb",
    "lib/web_svr/web_method.rb"
  ]

  spec.require_paths = ['lib']

  # 
  # Web specific dependencies
  # 
  spec.add_dependency 'thin', '~> 1.8.2'
end
