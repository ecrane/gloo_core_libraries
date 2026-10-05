require 'test_helper'

#
# A stand-in database error, as a driver's library would raise.
#
class FakeDbError < StandardError; end

#
# A minimal connection object that includes the shared driver
# behaviour, the way gloo-sqlite, gloo-mysql and gloo-pg do.
#
class FakeConnection < Gloo::Core::Obj

  include DbConnection

  #
  # The name of the object type.
  #
  def self.typename
    return 'fakedb'
  end

  #
  # The short name of the object type (every Obj subclass registers
  # itself as a type, so it needs one).
  #
  def self.short_typename
    return 'fakedb'
  end

  #
  # Only FakeDbError counts as a database error.
  #
  def database_errors
    return [ FakeDbError ]
  end

end

class DbConnectionTest < BaseEngineTest

  #
  # A connection object named db.
  #
  def create_connection
    conn = FakeConnection.new( @engine )
    conn.name = 'db'
    return conn
  end

  #
  # A connection that works puts true in it.
  #
  def test_verify_connection_puts_true_in_it
    conn = create_connection
    assert conn.verify_connection { true }
    assert_equal true, @engine.heap.it.value
    refute @engine.error?
  end

  #
  # A database error is a readable error, and it is false.
  #
  def test_verify_connection_reports_a_database_error
    conn = create_connection
    refute conn.verify_connection { raise FakeDbError, 'access denied' }

    assert_equal "Could not connect to fakedb 'db': access denied", @engine.heap.error.value
    assert_equal false, @engine.heap.it.value
  end

  #
  # A system error (eg. connection refused) is reported the same way.
  #
  def test_verify_connection_reports_a_system_error
    conn = create_connection
    refute conn.verify_connection { raise Errno::ECONNREFUSED }
    assert_includes @engine.heap.error.value, "Could not connect to fakedb 'db'"
  end

  #
  # Anything else is a real bug, not a connection problem: it isn't
  # reported as one.
  #
  def test_verify_connection_lets_other_errors_out
    conn = create_connection
    assert_raises( NoMethodError ) { conn.verify_connection { nil.no_such } }
  end

  #
  # A setup problem is reported, and there's no result.
  #
  def test_setup_err_reports_and_returns_nil
    conn = create_connection
    assert_nil conn.setup_err( 'The database name is required!' )
    assert_equal 'The database name is required!', @engine.heap.error.value
  end

  #
  # Without an override, every StandardError is a database error.
  #
  def test_database_errors_default
    obj = Gloo::Core::Obj.new( @engine )
    obj.extend( DbConnection )
    assert_equal [ StandardError ], obj.database_errors
  end

end
