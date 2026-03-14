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

  # Get the email mailbox.
  #
  def mailbox
    return find_child_value MAILBOX
  end

  # Get the email search.
  #
  def search
    return find_child_value SEARCH
  end

  # Get the email mark as read.
  #
  def mark_as_read
    val = find_child_value MARK_AS_READ
    puts "Mark as read value: #{val}"
    return val == 'true'
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
    ids = imap.search([search])

    if ids.empty?
      puts "No new messages."
    else
      ids.each do |msg_id|
        raw_message = imap.fetch(msg_id, "RFC822")[0].attr["RFC822"]
        mail = Mail.read_from_string(raw_message)

        puts "------------------------"
        puts "From: #{mail.from.join(', ')}"
        puts "Subject: #{mail.subject}"
        puts "Date: #{mail.date}"
        puts "Body:"
        puts mail.body.decoded
        puts "------------------------"

        # # Mark as seen (optional)
        # if mark_as_read
        #   puts "Marking message as read"
        #   imap.store(msg_id, "+FLAGS", [:Seen])
        # else
        #   puts "Marking message as unread"
        #   imap.store(msg_id, "-FLAGS", [:Seen])
        # end
      end
    end

    # -----------------------------
    # CLEAN UP
    # -----------------------------
    imap.logout
    imap.disconnect  
  end

end
