require 'test_helper'

#
# A minimal stand-in for a pg gem connection. Pg#pg_conn hardcodes
# `PG.connect` (no other injection seam), so tests here stub that
# module method directly via Minitest's Object#stub - never a real
# TCP connection, but the real result-shaping logic in query/
# connects? runs for real. No Postgres server is reachable on this
# machine (checked before writing this), but the discipline is the
# same as gloo-mysql's regardless: never connect to a real server
# from a test.
#
class FakePgConnection

  attr_reader :closed

  #
  # Set up with the rows to return, or an error to raise.
  #
  def initialize( rows, error = nil )
    @rows = rows
    @error = error
    @closed = false
  end

  #
  # Run a query: return the rows, or raise the error.
  #
  def exec( _sql )
    raise @error if @error

    return @rows
  end

  #
  # Run a query with parameters.
  #
  def exec_params( _sql, _params )
    raise @error if @error

    return @rows
  end

  #
  # Close the connection.
  #
  def close
    @closed = true
  end

end

class PgTest < BaseEngineTest

  def test_the_typename
    assert_equal 'postgres', Pg.typename
  end

  def test_the_short_typename
    assert_equal 'pg', Pg.short_typename
  end

  def test_doc_data
    data = Pg.doc_data
    assert_equal Pg.typename, data[ :name ]
    assert_equal Pg.short_typename, data[ :shortcut ]
  end

  def test_find_type
    assert @dic.find_obj( 'postgres' )
    assert @dic.find_obj( 'pg' )
    assert @dic.find_obj( 'PG' )
  end

  def test_messages
    msgs = Pg.messages
    assert msgs
    assert msgs.include?( 'verify' )
    assert msgs.include?( 'unload' )
  end

  def test_adds_children_on_create
    o = Pg.new( @engine )
    assert o.add_children_on_create?
  end

  def test_that_children_are_added_on_create
    i = @engine.parser.parse_immediate 'create o as pg'
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

  def create_pg
    i = @engine.parser.parse_immediate 'create o as pg'
    i.run
    return @engine.heap.root.find_child( 'o' )
  end

  def test_verify_returns_false_and_records_the_error_on_a_connection_failure
    o = create_pg
    PG.stub( :connect, ->( *_args, **_kwargs ) { raise PG::ConnectionBad, 'simulated connection failure' } ) do
      o.msg_verify
    end

    assert_equal false, @engine.heap.it.value
    assert_equal "Could not connect to postgres 'o': simulated connection failure", @engine.heap.error.value
  end

  def test_verify_returns_true_when_the_client_connects
    o = create_pg
    PG.stub( :connect, ->( *_args, **_kwargs ) { FakePgConnection.new( [] ) } ) do
      o.msg_verify
    end

    assert_equal true, @engine.heap.it.value
  end

  def test_query_without_params_returns_heads_and_rows
    o = create_pg
    fake_conn = FakePgConnection.new( [ { 'id' => 1, 'name' => 'Ann' }, { 'id' => 2, 'name' => 'Bo' } ] )

    heads, rows = PG.stub( :connect, ->( *_args, **_kwargs ) { fake_conn } ) do
      o.query( 'SELECT id, name FROM t' )
    end

    assert_equal [ 'id', 'name' ], heads
    assert_equal [ [ 1, 'Ann' ], [ 2, 'Bo' ] ], rows
  end

  def test_query_with_params_returns_heads_and_rows
    o = create_pg
    fake_conn = FakePgConnection.new( [ { 'name' => 'Ann' } ] )

    heads, rows = PG.stub( :connect, ->( *_args, **_kwargs ) { fake_conn } ) do
      o.query( 'SELECT name FROM t WHERE id = $1', [ 1 ] )
    end

    assert_equal [ 'name' ], heads
    assert_equal [ [ 'Ann' ] ], rows
  end

  def test_query_returns_empty_heads_and_rows_when_there_are_no_results
    o = create_pg
    fake_conn = FakePgConnection.new( [] )

    heads, rows = PG.stub( :connect, ->( *_args, **_kwargs ) { fake_conn } ) do
      o.query( 'DELETE FROM t' )
    end

    assert_equal [], heads
    assert_equal [], rows
  end

  #
  # A connection failure comes out of query as an exception, for
  # gloo-db's Query to report (the shared driver rule).
  #
  def test_query_raises_when_the_connection_itself_fails
    o = create_pg

    assert_raises( PG::ConnectionBad ) do
      PG.stub( :connect, ->( *_args, **_kwargs ) { raise PG::ConnectionBad, 'boom' } ) do
        o.query( 'SELECT 1' )
      end
    end
  end

  def test_get_query_result_builds_a_query_result_from_the_query_shape
    o = create_pg
    result = o.get_query_result( [ [ 'id' ], [ [ 1 ], [ 2 ] ] ] )

    assert_kind_of QueryResult, result
    assert result.has_data_to_show?
  end

  #
  # verify closes the connection it opened.
  #
  def test_verify_closes_the_connection
    o = create_pg
    conn = FakePgConnection.new( [] )
    PG.stub( :connect, ->( *_args, **_kwargs ) { conn } ) { o.msg_verify }
    assert conn.closed
  end

  #
  # query closes its connection, also when the query fails.
  #
  def test_query_closes_the_connection
    o = create_pg
    conn = FakePgConnection.new( [] )
    PG.stub( :connect, ->( *_args, **_kwargs ) { conn } ) { o.query( 'SELECT 1' ) }
    assert conn.closed

    bad = FakePgConnection.new( [], PG::Error.new( 'bad' ) )
    PG.stub( :connect, ->( *_args, **_kwargs ) { bad } ) do
      assert_raises( PG::Error ) { o.query( 'SELEC 1' ) }
    end
    assert bad.closed
  end

  #
  # PG errors are the driver's database errors.
  #
  def test_database_errors
    assert_equal [ PG::Error ], create_pg.database_errors
  end

  #
  # Through gloo-db's query: a database error is one readable error,
  # and it is false.
  #
  def test_query_run_with_a_database_error_is_a_readable_error
    create_pg
    @engine.parser.run 'create q as query'
    @engine.parser.run "put 'o' into q.database*"
    @engine.parser.run "put 'SELECT * FROM nope' into q.sql"
    conn = FakePgConnection.new( [], PG::Error.new( 'relation "nope" does not exist' ) )
    PG.stub( :connect, ->( *_args, **_kwargs ) { conn } ) { @engine.parser.run 'tell q to run' }

    assert_equal 'Query failed: relation "nope" does not exist', @engine.heap.error.value
    assert_equal false, @engine.heap.it.value
  end

end
