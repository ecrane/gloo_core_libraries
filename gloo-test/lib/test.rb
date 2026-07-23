#
# A gloo unit test object
#
class Test < Gloo::Core::Obj

  KEYWORD = 'test'.freeze
  TEST_DESC = 'description'.freeze
  ON_TEST_EVENT = 'on_test'.freeze


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
  # Get the test description.
  #
  def test_desc
    o = find_child TEST_DESC
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
    fac.create_string TEST_DESC, '', self
    fac.create_script ON_TEST_EVENT, '', self
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

  # 
  # Run the test.
  #
  def run_test
    result = Result.new( @engine, self )
    @engine.context_object = result
    run_on_test
    @engine.context_object = nil

    result.show_result_symbol

    return result
  end

  #
  # Run the on_test script.
  #
  def run_on_test
    o = find_child ON_TEST_EVENT
    return unless o

    Gloo::Exec::Dispatch.message( @engine, 'run', o )
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
      :description => 'A single gloo test.',
      :children => [
        'description (string) — A textual description of the test and desired outcome, used in output if there is an error.',
        'on_test (script) — The script to run when the test is executed. Note that the normal way to run tests is with gloo --test.'
      ],
      :examples => <<~EXAMPLES.strip
        #
        # Basic tests
        #
        tests [can] :
          basic [can] :

            on_load [script] :
              log 'Include functionality for all test in on_load' (debug)

            assert_noop [test] :
              description [string] : Assert no operation
              on_test [script] :
                noop
                assert 'noop should be true'
      EXAMPLES
    }
  end

end
