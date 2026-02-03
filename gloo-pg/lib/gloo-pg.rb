# 
# Shim to allow `require 'gloo-pg'`
# 
# This file is loaded when someone does `require 'gloo-pg'`
# 
require 'pg'

# 
# Registers the extension.
# 
class PgInit < Gloo::Plugin::Base

    # 
    # Register verbs and objects.
    # 
    def register( callback )
      callback.register_obj( Pg )
    end

end
