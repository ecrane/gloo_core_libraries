require 'test_helper'

#
# Minimal stand-ins for the mysql2 gem's Client/PreparedStatement/
# result-set objects. Mysql#get_client hardcodes `Mysql2::Client.new`
# (no injection seam), so tests here stub that class method directly
# via Minitest's Object#stub - never a real TCP connection, but the
# real error-handling and result-shaping code in query/connects? runs
# for real. There IS a live MySQL server reachable on localhost:3306
# on this machine; deliberately never connected to from any test -
# unknown credentials, unknown blast radius, same rule as gloo-web's
# network caution.
#
class FakeMysql2ResultSet
  attr_reader :fields

  def initialize( fields, rows )
    @fields = fields
    @rows = rows
  end

  def each( &block )
    @rows.each( &block )
  end
end

class FakeMysql2PreparedStatement
  def initialize( result_set )
    @result_set = result_set
  end

  def execute( *_params, **_opts )
    return @result_set
  end
end

class FakeMysql2Client

  def initialize( fields, rows )
    @result_set = FakeMysql2ResultSet.new( fields, rows )
  end

  def ping
    return true
  end

  def query( _sql, **_opts )
    return @result_set
  end

  def prepare( _sql )
    return FakeMysql2PreparedStatement.new( @result_set )
  end

end

class MysqlTest < BaseEngineTest

  def test_the_typename
    assert_equal 'mysql', Mysql.typename
  end

  def test_the_short_typename
    assert_equal 'mysql', Mysql.short_typename
  end

  def test_find_type
    assert @dic.find_obj( 'mysql' )
    assert @dic.find_obj( 'MySQL' )
    assert @dic.find_obj( 'Mysql' )
  end

  def test_messages
    msgs = Mysql.messages
    assert msgs
    assert msgs.include?( 'verify' )
    assert msgs.include?( 'unload' )
  end

  def test_adds_children_on_create
    o = Mysql.new( @engine )
    assert o.add_children_on_create?
  end

  def test_that_children_are_added_on_create
    i = @engine.parser.parse_immediate 'create o as mysql'
    i.run
    assert_equal 1, @engine.heap.root.child_count
    obj = @engine.heap.root.children.first
    assert obj
    assert_equal 'o', obj.name
    assert_equal 4, obj.child_count
    assert_equal 'host', obj.children.first.name
    assert_equal 'database', obj.children[ 1 ].name
    assert_equal 'username', obj.children[ 2 ].name
    assert_equal 'password', obj.children.last.name
  end

  def create_mysql
    i = @engine.parser.parse_immediate 'create o as mysql'
    i.run
    return @engine.heap.root.find_child( 'o' )
  end

  #
  # The original version of this test put 'localhost' as the host
  # and called the real 'verify' message expecting it to fail (no
  # username/database/password set). That happened to pass, but only
  # because it was actually reaching the real MySQL server on this
  # machine and getting an auth rejection - a real, if incidental,
  # network dependency this suite shouldn't have. Stubbing
  # Mysql2::Client.new exercises the exact same error-handling code
  # path deterministically, without ever touching the network.
  #
  def test_verify_returns_false_and_records_the_error_on_a_connection_failure
    o = create_mysql
    Mysql2::Client.stub( :new, ->( *_args ) { raise StandardError, 'simulated connection failure' } ) do
      o.msg_verify
    end

    assert_equal false, @engine.heap.it.value
    assert @engine.error?
  end

  def test_verify_returns_true_when_the_client_connects
    o = create_mysql
    Mysql2::Client.stub( :new, ->( *_args ) { FakeMysql2Client.new( [], [] ) } ) do
      o.msg_verify
    end

    assert_equal true, @engine.heap.it.value
  end

  def test_query_without_params_returns_heads_and_rows
    o = create_mysql
    fake_client = FakeMysql2Client.new( [ 'id', 'name' ], [ [ 1, 'Ann' ], [ 2, 'Bo' ] ] )

    heads, rows = Mysql2::Client.stub( :new, ->( *_args ) { fake_client } ) do
      o.query( 'SELECT id, name FROM t' )
    end

    assert_equal [ 'id', 'name' ], heads
    assert_equal [ [ 1, 'Ann' ], [ 2, 'Bo' ] ], rows
  end

  def test_query_with_params_returns_heads_and_rows
    o = create_mysql
    fake_client = FakeMysql2Client.new( [ 'name' ], [ [ 'Ann' ] ] )

    heads, rows = Mysql2::Client.stub( :new, ->( *_args ) { fake_client } ) do
      o.query( 'SELECT name FROM t WHERE id = ?', [ 1 ] )
    end

    assert_equal [ 'name' ], heads
    assert_equal [ [ 'Ann' ] ], rows
  end

  #
  # query's own rescue only guards the query-execution step -
  # get_client (and Mysql2::Client.new inside it) runs before the
  # begin block, so a connection failure propagates as a raised
  # exception rather than being swallowed into an empty result. Same
  # shape in gloo-sqlite's Sqlite#query - not a bug, just the actual
  # contract: Query#run_query (gloo-db), the caller, has its own
  # outer rescue for exactly this.
  #
  def test_query_raises_when_the_connection_itself_fails
    o = create_mysql

    assert_raises( StandardError ) do
      Mysql2::Client.stub( :new, ->( *_args ) { raise StandardError, 'boom' } ) do
        o.query( 'SELECT 1' )
      end
    end
  end

  def test_get_query_result_builds_a_query_result_from_the_query_shape
    o = create_mysql
    result = o.get_query_result( [ [ 'id' ], [ [ 1 ], [ 2 ] ] ] )

    assert_kind_of QueryResult, result
    assert result.has_data_to_show?
  end

end
