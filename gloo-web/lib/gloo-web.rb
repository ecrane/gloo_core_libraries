# 
# Shim to allow `require 'gloo-web'`
# 
# This file is loaded when someone does `require 'gloo-web'`
# 
require 'objs/element'
require 'objs/field'
require 'objs/form'
require 'objs/page'
require 'objs/partial'
require 'objs/svr'

require 'routing/show_routes'
require 'routing/resource_router'
require 'routing/router'

require 'web_svr/asset_info'
require 'web_svr/asset'
require 'web_svr/config'
require 'web_svr/embedded_renderer'
require 'web_svr/handler'
require 'web_svr/request_params'
require 'web_svr/request'
require 'web_svr/response_code'
require 'web_svr/response'
require 'web_svr/server'
require 'web_svr/session'
require 'web_svr/table_renderer'
require 'web_svr/web_method'

# 
# Registers the extension.
# 
class WebInit < Gloo::Plugin::Base

    # 
    # Register verbs and objects.
    # 
    def register( callback )
      callback.register_obj( Objs::Element )
      callback.register_obj( Objs::Field )
      callback.register_obj( Objs::Form )
      callback.register_obj( Objs::Page )
      callback.register_obj( Objs::Partial )
      callback.register_obj( Objs::Svr )
    end

end
