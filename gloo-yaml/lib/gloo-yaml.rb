#
# Shim to allow `require 'gloo-yaml'`
#
require 'yaml_obj'

#
# Registers the extension.
#
class YamlInit < Gloo::Plugin::Base

  #
  # Register verbs and objects.
  #
  def register( callback )
    callback.register_obj( YamlObj )
  end

end
