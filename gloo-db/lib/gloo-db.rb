# 
# Shim to allow `require 'gloo-mysql'`
# 
# This file is loaded when someone does `require 'gloo-mysql'`
# 
require 'query'
require 'query_result'
require 'table'

# 
# Registers the extension.
# 
class DbInit < Gloo::Plugin::Base

    # 
    # Register verbs and objects.
    # 
    def register( callback )
      callback.register_obj( Query )
      callback.register_obj( Table )
    end

end
