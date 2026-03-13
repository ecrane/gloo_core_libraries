#
# An email IMAP object
#
class EmailImap < Gloo::Core::Obj

  KEYWORD = 'email_imap'.freeze
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
    return super # + [ 'run' ]
  end

end
