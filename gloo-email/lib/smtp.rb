# 
# An SMTP email sender
# 
require 'mail'
require 'config'
require 'msg'

class Smtp

  attr_accessor :config
  
  # 
  # Initialize a new SMTP email sender.
  # 
  def initialize( config )
    @config = config
  end

  # 
  # Send an email message.
  # 
  def send msg
    begin
      configure
      mail = msg.get_mail

      mail.deliver!
      puts "Email sent successfully!"
    rescue => e
      puts "Failed to send email:"
      puts e.message
    end
  end

  # 
  # Configure the SMTP settings.
  # 
  def configure
    svr = @config.host
    prt = @config.port
    usr = @config.username
    pwd = @config.password
    
    Mail.defaults do
      delivery_method :smtp, {
        address: svr,
        port: prt,
        user_name: usr,
        password: pwd,
        authentication: :plain,
        enable_starttls_auto: true
      }
    end
  end

end
