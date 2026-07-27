#
# An email IMAP object
#
require 'net/imap'
require 'mail'

class EmailImap < Gloo::Core::Obj

  KEYWORD = 'email_imap'.freeze
  SERVER = 'server'.freeze
  PORT = 'port'.freeze
  USERNAME = 'username'.freeze
  PASSWORD = 'password'.freeze
  MAILBOX = 'mailbox'.freeze
  MESSAGES = 'messages'.freeze
  SEARCH = 'UNSEEN'.freeze

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
  # Get the email server host.
  #
  def server
    return find_child_value SERVER
  end

  #
  # Get the email server port.
  #
  def port
    return find_child_value PORT
  end

  #
  # Get the email username.
  #
  def username
    return find_child_value USERNAME
  end

  #
  # Get the email password.
  #
  def password
    return find_child_value PASSWORD
  end

  #
  # Get the email mailbox.
  #
  def mailbox
    return find_child_value MAILBOX
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
    fac.create_string MAILBOX, '', self
    fac.create_can MESSAGES, self
  end


  # ---------------------------------------------------------------------
  #    Messages
  # ---------------------------------------------------------------------

  #
  # Get a list of message names that this object receives.
  #
  def self.messages
    return super + [ 'fetch' ]
  end

  #
  # Fetch emails from the IMAP server.
  #
  def msg_fetch
    # Connect to the email server
    imap = Net::IMAP.new(server, port, true)
    imap.login(username, password)
    imap.select(mailbox)

    # Search for messages matching filter
    ids = imap.search([SEARCH])

    if ids.empty?
      puts "No new messages."
    else
      ids.each do |msg_id|
        raw_message = imap.fetch( msg_id, "RFC822" )[0].attr["RFC822"]
        mail = Mail.read_from_string( raw_message )
        process_message( mail )
      end
    end

    # -----------------------------
    # CLEAN UP
    # -----------------------------
    imap.logout
    imap.disconnect  
  end

  #
  # Process a single email message
  #
  def process_message( mail )
    from = mail.from.join(', ')
    to = mail.to.join(', ')
    subject = mail.subject
    dt = mail.date
    body = mail.body.decoded

    msg_can = find_child MESSAGES
    
    msg = msg_can.find_add_child( msg_can.children.length.to_s, 'email' )
    o = msg.find_add_child( 'from', 'string' )
    o.set_value from
    o = msg.find_add_child( 'to', 'string' )
    o.set_value to
    o = msg.find_add_child( 'subject', 'string' )
    o.set_value subject
    o = msg.find_add_child( 'date', 'string' )
    o.set_value dt
    o = msg.find_add_child( 'body', 'text' )
    o.set_value body
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
      :description => 'An IMAP email connection, used to fetch ' \
        'unseen messages from a mailbox.',
      :children => [
        'server (string) — The IMAP server host.',
        'port (string) — The IMAP server port.',
        'username (string) — The username with which to connect.',
        "password (string) — The user's password.",
        'mailbox (string) — The mailbox to select (e.g. INBOX).',
        'messages (container) — Populated by fetch: one child per unseen message found, each an email object with from/to/subject/date/body.'
      ],
      :messages => [
        'fetch — Connect to the IMAP server, select the mailbox, and fetch all unseen messages, adding each as a child of messages. Logs out and disconnects when done.'
      ],
      :notes => 'No vault documentation exists for this object type — ' \
        'this was authored directly from the code.',
      :examples => <<~EXAMPLES.strip
        mail [can] :
          inbox [email_imap] :
            server : imap.example.com
            port : 993
            username : me@example.com
            password : secret
            mailbox : INBOX

          on_load [script] :
            tell mail.inbox to fetch
            list mail.inbox.messages
      EXAMPLES
    }
  end

end
