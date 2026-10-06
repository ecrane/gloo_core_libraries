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
  def initialize( engine, config )
    @engine = engine
    @config = config
  end

  # 
  # Deliver an email message. Returns true if it was sent; otherwise
  # reports a readable error (no backtrace: a refused login, an
  # unreachable server or a bad address are expected) and returns
  # false.
  # 
  def deliver msg
    configure
    msg.get_mail.deliver!
    @engine.log.info "Email sent successfully!"
    return true
  rescue => ex
    @engine.err "Could not send email: #{ex.message}"
    return false
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
