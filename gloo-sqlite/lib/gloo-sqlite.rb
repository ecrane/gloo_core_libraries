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

    #
    # Load the version from the VERSION file.
    #
    def self.get_version
      f = File.dirname( File.absolute_path( __FILE__ ) )
      f = File.dirname( File.dirname( f ) )
      f = File.join( f, VERSION_FILE )
      return File.read( f )
    end

    VERSION = SqliteInit.get_version

end
