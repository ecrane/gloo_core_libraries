# 
# Shim to allow `require 'gloo-beep'`
# 
# This file is loaded when someone does `require 'gloo-beep'`
# 
require 'gloo_beep'
require 'beep'

# 
# Registers the extension.
# 
class BeepInit < Gloo::Plugin::Base

    # 
    # Register verbs and objects.
    # 
    def register( callback )
      callback.register_verb( Beep )
      puts "Beep library loaded!!!"
    end

end
