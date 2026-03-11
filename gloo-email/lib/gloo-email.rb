# 
# Shim to allow `require 'gloo-email'`
# 
# This file is loaded when someone does `require 'gloo-email'`
# 
require 'email_smtp'
require 'email_imap'
require 'email_msg'

# 
# Registers the extension.
# 
class EmailInit < Gloo::Plugin::Base

    # 
    # Register verbs and objects.
    # 
    def register( callback )
      callback.register_obj( EmailSmtp )
      callback.register_obj( EmailImap )
      callback.register_obj( EmailMsg )
    end

end
