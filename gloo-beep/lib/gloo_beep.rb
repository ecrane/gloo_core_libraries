# 
# Registers the t extension.
# 
class GlooBeep < Gloo::Plugin::Base

    # 
    # Register verbs and objects.
    # 
    def register( callback )
      require_relative 'beep'

      callback.register_verb( Beep )
      puts "Beep library loaded!!!"
    end

end
