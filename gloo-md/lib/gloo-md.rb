# 
# Shim to allow `require 'gloo-md'`
# 
# This file is loaded when someone does `require 'gloo-md'`
# 
require 'md'
require 'md_doc'
require 'markdown_ext'

#
# Registers the extension.
#
class MdInit < Gloo::Plugin::Base

    #
    # Register verbs and objects.
    #
    def register( callback )
      callback.register_obj( Md )
      callback.register_obj( MdDoc )
    end

end
