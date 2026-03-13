#
# An email message object
#
class EmailMsg < Gloo::Core::Obj

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

end
