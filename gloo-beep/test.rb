# 
# Just a quick test to make sure the gem loads correctly
# 

module Gloo
  module Core
    class Verb
    end
  end
  module Plugin
    class Base
    end
  end
end

require 'gloo-beep' 

Beep.new.run
