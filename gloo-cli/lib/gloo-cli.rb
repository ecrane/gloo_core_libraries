# 
# Shim to allow `require 'gloo-cli'`
# 
# This file is loaded when someone does `require 'gloo-cli'`
# 
require 'colorize'
require 'cli_confirm'
require 'menu'
require 'menu_item'
require 'prompt'
require 'select'

# 
# Registers the extension.
# 
class CliInit < Gloo::Plugin::Base

    # 
    # Register verbs and objects.
    # 
    def register( callback )
      callback.register_obj( Colorize )
      callback.register_obj( CliConfirm )
      callback.register_obj( Menu )
      callback.register_obj( MenuItem )
      callback.register_obj( Prompt )
      callback.register_obj( Select )
    end

end
