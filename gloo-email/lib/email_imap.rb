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
  # Fetch the unseen emails from the IMAP server into messages.
  # It is true if it could fetch them (even if there were none),
  # false otherwise.
  #
  def msg_fetch
    mails = fetch_unseen
    if mails
      @engine.log.info "No new messages." if mails.empty?
      mails.each { |mail| process_message( mail ) }
    end

    @engine.heap.it.set_to( mails ? true : false )
  end

  #
  # Get the unseen messages from the server, as Mail messages.
  # If it can't (an unreachable server, a refused login, no such
  # mailbox), report a readable error and return nil. The connection
  # is always closed.
  #
  def fetch_unseen
    imap = Net::IMAP.new( server, port, true )
    imap.login( username, password )
    imap.select( mailbox )

    # Search for messages matching filter
    ids = imap.search( [ SEARCH ] )

    return ids.map do |msg_id|
      raw_message = imap.fetch( msg_id, "RFC822" )[0].attr["RFC822"]
      Mail.read_from_string( raw_message )
    end
  rescue => e
    @engine.err "Could not fetch email from #{server}: #{e.message}"
    return nil
  ensure
    close_imap( imap )
  end

  #
  # Log out and disconnect, if connected.
  #
  def close_imap( imap )
    return unless imap

    imap.logout
    imap.disconnect
  rescue StandardError
    # The connection already failed or was closed; nothing to do.
    nil
  end

  #
  # Process a single email message
  #
  def process_message( mail )
    # A message may have no From: or To: (eg. when we were Bcc'd).
    from = Array( mail.from ).join(', ')
    to = Array( mail.to ).join(', ')
    subject = mail.subject
    dt = mail.date
    body = mail.body.decoded

    msg_can = find_child( MESSAGES ) || @engine.factory.create_can( MESSAGES, self )
    
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
        'fetch — Connect to the IMAP server, select the mailbox, and fetch all unseen messages, adding each as a child of messages (created if missing). Logs out and disconnects when done. It is true if it could fetch (even if there were no new messages), false otherwise (eg. a refused login or an unreachable server, reported as an error).'
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
