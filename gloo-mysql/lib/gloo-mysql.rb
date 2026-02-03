# 
# Shim to allow `require 'gloo-mysql'`
# 
# This file is loaded when someone does `require 'gloo-mysql'`
# 
require 'mysql'

# 
# Registers the extension.
# 
class MysqlInit < Gloo::Plugin::Base

    # 
    # Register verbs and objects.
    # 
    def register( callback )
      callback.register_obj( Mysql )
    end

end
