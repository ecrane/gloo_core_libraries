# 
# Shim to allow `require 'gloo-sqlite'`
# 
# This file is loaded when someone does `require 'gloo-sqlite'`
# 
require 'sqlite'

# 
# Registers the extension.
# 
class SqliteInit < Gloo::Plugin::Base

    # 
    # Register verbs and objects.
    # 
    def register( callback )
      callback.register_obj( Sqlite )
    end

end
