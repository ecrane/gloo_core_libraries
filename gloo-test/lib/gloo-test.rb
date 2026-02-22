# 
# Shim to allow `require 'gloo-test'`
# 
# This file is loaded when someone does `require 'gloo-test'`
# 
require 'assert'
require 'refute'
require 'result'
require 'results'
require 'test_file'
require 'test_files'
require 'test_runner'
require 'test'

# 
# Registers the extension.
# 
class TestInit < Gloo::Plugin::Base

    # 
    # Register verbs and objects.
    # 
    def register( callback )
      callback.register_obj( Test )
      callback.register_verb( Assert )
      callback.register_verb( Refute )
    end

end
