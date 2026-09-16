#
# Shim to allow `require 'gloo-pg'`
#
# This file is loaded when someone does `require 'gloo-pg'`
#
# The driver's own file is 'pg_obj.rb', not 'pg.rb' - it would
# otherwise collide with the real `pg` gem's own top-level pg.rb
# (identical require-path), silently shadowing it depending on
# which one happens to resolve first on $LOAD_PATH. Same fix gloo-
# yaml already applies for a stdlib collision (yaml_obj.rb).
#
require 'pg_obj'

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
