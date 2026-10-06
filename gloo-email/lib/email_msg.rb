#
# An email message object
#
require 'email_param'

class EmailMsg < Gloo::Core::Obj

  include EmailParam

  KEYWORD = 'email'.freeze
  SUBJECT = 'subject'.freeze
  BODY = 'body'.freeze
  TO = 'to'.freeze
  FROM = 'from'.freeze
  WHEN = 'when'.freeze

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
  # Get the email subject.
  #
  def subject
    return find_child_value SUBJECT
  end
  
  # Get the email body.
  #
  def body
    return find_child_value BODY
  end
  
  # Get the email to.
  #
  def to
    return find_child_value TO
  end
  
  # Get the email from.
  #
  def from
    return find_child_value FROM
  end

  # 
  # Get the mail message to send.
  # 
  # Returns:
  #   A mail message.
  # 
  def get_msg
    return Msg.new( to, from, subject, body )
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
    fac.create_string TO, '', self
    fac.create_string FROM, '', self
    fac.create_string SUBJECT, '', self
    fac.create_text BODY, '', self
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
  # Send this message with the email_smtp given as the parameter.
  # It is true if it was sent, false otherwise.
  #
  def msg_send
    smtp = param_obj( EmailSmtp, 'email_smtp object',
      "tell #{name} to send (my.smtp)" )
    send_msg( smtp && get_msg, smtp&.get_config )
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
      :description => 'An email message — the recipient, sender, ' \
        'subject and body to send.',
      :children => [
        'to (string) — The recipient email address.',
        'from (string) — The sender email address.',
        'subject (string) — The email subject.',
        'body (text) — The email body.'
      ],
      :messages => [
        'send ({smtp.path}) — Send this message using the given SMTP configuration object. A parameter is required: the path to an email_smtp object. It is true if the message was sent, false otherwise (eg. a refused login or an unreachable server, reported as an error).'
      ],
      :notes => 'No vault documentation exists for this object type — ' \
        'this was authored directly from the code.',
      :examples => <<~EXAMPLES.strip
        mail [can] :
          smtp [email_smtp] :
            server : smtp.example.com
            port : 587
            username : me@example.com
            password : secret

          msg [email] :
            to : someone@example.com
            from : me@example.com
            subject : Hello
            body [text] : BEGIN
              A message sent from gloo.
              END

          on_load [script] :
            tell mail.msg to send (mail.smtp)
      EXAMPLES
    }
  end

end
