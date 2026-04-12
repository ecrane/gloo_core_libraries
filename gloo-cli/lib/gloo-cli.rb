# 
# Shim to allow `require 'gloo-cli'`
# 
# This file is loaded when someone does `require 'gloo-cli'`
# 
require 'cli_colorize'
require 'cli_confirm'
require 'menu'
require 'menu_item'
require 'prompt'
require 'select'
require 'shell'
require 'shell_runner'
require 'shell_context'
require 'command_node'
require 'command'

# 
# Registers the extension.
# 
class CliInit < Gloo::Plugin::Base

    # 
    # Register verbs and objects.
    # 
    def register( callback )
      callback.register_obj( CliColorize )
      callback.register_obj( CliConfirm )
      callback.register_obj( Menu )
      callback.register_obj( MenuItem )
      callback.register_obj( Prompt )
      callback.register_obj( Select )
      callback.register_obj( Shell )
      callback.register_obj( Command )
    end

end
