# 
# An Mail Server Configuration
# 

class Config

  attr_accessor :host, :port, :username, :password
  
  # 
  # Initialize a new SMTP email sender.
  # 
  def initialize( host, port, username, password )
    @host = host
    @port = port
    @username = username
    @password = password
  end

end
