#
# An email SMTP configuration object
#
require 'config'
require 'msg'
require 'smtp'

class EmailSmtp < Gloo::Core::Obj

  KEYWORD = 'email_smtp'.freeze
  SERVER = 'server'.freeze
  PORT = 'port'.freeze
  USERNAME = 'username'.freeze
  PASSWORD = 'password'.freeze


  #
  # The name of the object type.
  #
  def self.typename
    return KEYWORD
  end

  #
  # The short name of the object type.
  # Same as the typename.
  #
  def self.short_typename
    return KEYWORD
  end

  # 
  # Get the email server.
  #
  def server
    o = find_child SERVER
    return o ? o.value : 'Unknown'
  end

  # Get the email port.
  #
  def port
    o = find_child PORT
    return o ? o.value : 'Unknown'
  end

  # Get the email username.
  #
  def username
    o = find_child USERNAME
    return o ? o.value : 'Unknown'
  end

  # Get the email password.
  #
  def password
    o = find_child PASSWORD
    return o ? o.value : 'Unknown'
  end


  # ---------------------------------------------------------------------
  #    Children
  # ---------------------------------------------------------------------

  # Does this object have children to add when an object
  # is created in interactive mode?
  # This does not apply during obj load, etc.
  def add_children_on_create?
    return true
  end

  # Add children to this object.
  # This is used by containers to add children needed
  # for default configurations.
  def add_default_children
    fac = @engine.factory
    fac.create_string SERVER, '', self
    fac.create_string PORT, '', self
    fac.create_string USERNAME, '', self
    fac.create_string PASSWORD, '', self
  end


  # ---------------------------------------------------------------------
  #    Messages
  # ---------------------------------------------------------------------

  #
  # Get a list of message names that this object receives.
  #
  def self.messages
    return super + [ 'send' ]
  end

  #
  # Send an email.
  #
  def msg_send
    to = "eric.crane@mac.com"
    from = "eric.n.crane@gmail.com"
    subject = "Test Email from gloo"
    body = "Woot!\n\nThis is a test email sent from gloo."
    msg = Msg.new( to, from, subject, body )
    puts msg

    smtp = Smtp.new( get_config )
    smtp.send msg
  end

  # 
  # Get the configuration for this SMTP server.
  #
  def get_config
    config = Config.new( server, port, username, password )
    return config
  end

end
