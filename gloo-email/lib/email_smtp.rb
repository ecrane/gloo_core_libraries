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
    return find_child_value SERVER
  end

  # Get the email port.
  #
  def port
    return find_child_value PORT
  end

  # Get the email username.
  #
  def username
    return find_child_value USERNAME
  end

  # Get the email password.
  #
  def password
    return find_child_value PASSWORD
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
    if @params&.token_count&.positive?
      msg_pn = Gloo::Core::Pn.new( @engine, @params.tokens.first )
      unless msg_pn&.exists?
        @engine.err 'Email Message does not exist'
        return
      end
    else
      @engine.err 'Email Message is required'
      return
    end
    msg = msg_pn.resolve.get_msg

    smtp = Smtp.new( @engine, get_config )
    smtp.send msg
  end

  #
  # Get the configuration for this SMTP server.
  #
  def get_config
    config = Config.new( server, port, username, password )
    return config
  end

  # ---------------------------------------------------------------------
  #    Object Documentation
  # ---------------------------------------------------------------------

  #
  # Get the object's documentation data.
  #
  def self.doc_data
    {
      :name => KEYWORD,
      :shortcut => KEYWORD,
      :description => 'An email SMTP configuration object, used to ' \
        'send email messages.',
      :children => [
        'server (string) — The SMTP server host.',
        'port (string) — The SMTP server port.',
        'username (string) — The username with which to connect.',
        "password (string) — The user's password."
      ],
      :messages => [
        'send ({message.path}) — Send the given email message object using this SMTP configuration. A parameter is required: the path to an email message object.'
      ],
      :notes => 'No vault documentation exists for this object type — ' \
        'this was authored directly from the code.',
      :examples => <<~EXAMPLES.strip
        mail [can] :
          smtp [email_smtp] :
            server : smtp.example.com
            port : 587
            username : me@example.com
            password [alias] : mail.get_passwd.result

          msg [email] :
            to : someone@example.com
            from : me@example.com
            subject : Hello
            body [text] : BEGIN
              A message sent from gloo.
              END

          on_load [script] :
            tell mail.smtp to send (mail.msg)
      EXAMPLES
    }
  end

end
