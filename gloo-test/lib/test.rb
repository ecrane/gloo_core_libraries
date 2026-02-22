#
# A gloo unit test object
#
class Test < Gloo::Core::Obj

  KEYWORD = 'test'.freeze
  KEYWORD_SHORT = 'case'.freeze
  TEST_NAME = 'name'.freeze
  TEST_EXPECTS = 'expects'.freeze
  TEST_ON_TEST = 'on_test'.freeze


  #
  # The name of the object type.
  #
  def self.typename
    return KEYWORD
  end

  #
  # The short name of the object type.
  #
  def self.short_typename
    return KEYWORD_SHORT
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
    fac.create_string TEST_NAME, '', self
    fac.create_string TEST_EXPECTS, '', self
    fac.create_script TEST_ON_TEST, '', self
  end


  # ---------------------------------------------------------------------
  #    Messages
  # ---------------------------------------------------------------------

  #
  # Get a list of message names that this object receives.
  #
  def self.messages
    return super + [ 'run' ]
  end

  #
  # Run the colorize command.
  #
  def msg_run
    # msg = ''
    # children.each do |o|
    #   msg += ColorizedString[ o.value_display ].colorize( o.name.to_sym )
    # end
    # @engine.log.show msg
    # @engine.heap.it.set_to msg.to_s
  end

end
