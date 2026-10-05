require 'test_helper'

#
# A minimal stand-in for a database connection object (what a
# concrete driver gem - gloo-sqlite, gloo-mysql, gloo-pg - actually
# provides). gloo-db itself is an abstract base with no real driver
# of its own, so Query's orchestration logic (result routing, param
# building, clearing stale results) is tested against this double
# rather than a live database. End-to-end "does a real query actually
# run" coverage belongs in a concrete driver gem's own test suite.
#
class FakeDb

  attr_reader :last_sql, :last_params

  def initialize( heads, rows )
    @heads = heads
    @rows = rows
  end

  def query( sql, params )
    @last_sql = sql
    @last_params = params
    return @rows
  end

  def get_query_result( result )
    return QueryResult.new( @heads, result )
  end

end

#
# A stand-in database error, as a driver's library would raise.
#
class FakeDbError < StandardError; end

#
# A stand-in database connection whose query raises the given error,
# as a driver does for bad SQL or a lost connection.
#
class RaisingDb

  #
  # Set up with the error to raise.
  #
  def initialize( error )
    @error = error
  end

  #
  # Raise the error.
  #
  def query( sql, params )
    raise @error
  end

  #
  # Only FakeDbError counts as a database error.
  #
  def database_errors
    return [ FakeDbError ]
  end

end

class QueryTest < BaseEngineTest

  def test_the_typename
    assert_equal 'query', Query.typename
  end

  def test_the_short_typename
    assert_equal 'sql', Query.short_typename
  end

  def test_doc_data
    data = Query.doc_data
    assert_equal Query.typename, data[ :name ]
    assert_equal Query.short_typename, data[ :shortcut ]
  end

  def test_find_type
    assert @dic.find_obj( 'query' )
    assert @dic.find_obj( 'SQL' )
    assert @dic.find_obj( 'sql' )
  end

  def test_messages
    msgs = Query.messages
    assert msgs
    assert msgs.include?( 'run' )
    assert msgs.include?( 'unload' )
  end

  def test_adds_children_on_create
    o = Query.new @engine
    assert o.add_children_on_create?
  end

  def test_that_children_are_added_on_create
    i = @engine.parser.parse_immediate 'create o as sql'
    i.run
    assert_equal 1, @engine.heap.root.child_count
    obj = @engine.heap.root.children.first
    assert obj
    assert_equal 'o', obj.name
    assert_equal 3, obj.child_count
    assert_equal 'database', obj.children.first.name
    assert_equal 'sql', obj.children[ 1 ].name
    assert_equal 'result', obj.children.last.name
  end

  def create_query
    i = @engine.parser.parse_immediate 'create o as sql'
    i.run
    return @engine.heap.root.find_child( 'o' )
  end

  def stub_db( o, fake_db )
    o.define_singleton_method( :db_obj ) { fake_db }
  end

  #
  # A database alias that doesn't point anywhere yet is reported as a
  # missing connection; it is false.
  #
  def test_msg_run_with_no_database_reports_an_error
    o = create_query
    o.msg_run

    assert_equal Query::DB_MISSING_ERR, @engine.heap.error.value
    assert_equal false, @engine.heap.it.value
  end

  #
  # Set the query's SQL.
  #
  def put_sql( sql )
    @engine.parser.parse_immediate( "put '#{sql}' into o.sql" ).run
  end

  #
  # A database alias that points at nothing is reported as not found.
  #
  def test_msg_run_with_a_database_alias_to_nothing_is_an_error
    o = create_query
    @engine.parser.parse_immediate( "put 'no_such_db' into o.database*" ).run
    put_sql 'SELECT 1'
    o.msg_run

    assert_equal Gloo::Core::NotFound.object( 'no_such_db' ), @engine.heap.error.value
    assert_equal false, @engine.heap.it.value
  end

  #
  # A database alias that points at something that isn't a database
  # connection is an error.
  #
  def test_msg_run_with_a_database_that_is_not_a_connection_is_an_error
    o = create_query
    @engine.parser.parse_immediate( 'create s as string' ).run
    @engine.parser.parse_immediate( "put 's' into o.database*" ).run
    put_sql 'SELECT 1'
    o.msg_run

    assert_equal "'s' is not a database connection.", @engine.heap.error.value
    assert_equal false, @engine.heap.it.value
  end

  #
  # Blank SQL is an error, and the driver isn't called.
  #
  def test_msg_run_with_no_sql_is_an_error
    o = create_query
    fake_db = FakeDb.new( [], [] )
    stub_db( o, fake_db )
    o.msg_run

    assert_includes @engine.heap.error.value, 'has no SQL'
    assert_equal false, @engine.heap.it.value
    assert_nil fake_db.last_sql
  end

  #
  # A query that runs puts true in it.
  #
  def test_msg_run_puts_true_in_it
    o = create_query
    stub_db( o, FakeDb.new( [ 'id' ], [ [ 1 ] ] ) )
    put_sql 'SELECT * FROM x'
    o.msg_run
    assert_equal true, @engine.heap.it.value
  end

  #
  # A database error is one readable error; it is false, and stale
  # results are cleared.
  #
  def test_msg_run_reports_a_database_error
    o = create_query
    stub_db( o, FakeDb.new( [ 'id' ], [ [ 1 ], [ 2 ] ] ) )
    put_sql 'SELECT * FROM x'
    o.msg_run

    stub_db( o, RaisingDb.new( FakeDbError.new( 'no such table: x' ) ) )
    o.msg_run

    assert_equal 'Query failed: no such table: x', @engine.heap.error.value
    assert_equal false, @engine.heap.it.value
    assert_equal 0, o.find_child( 'result' ).child_count
  end

  #
  # An error that isn't one of the driver's database errors is a real
  # bug, and isn't reported as a failed query.
  #
  def test_msg_run_lets_other_errors_out
    o = create_query
    stub_db( o, RaisingDb.new( NoMethodError.new( 'bug' ) ) )
    put_sql 'SELECT * FROM x'
    assert_raises( NoMethodError ) { o.msg_run }
  end

  #
  # A driver that reports a setup problem and returns no result makes
  # the query fail.
  #
  def test_msg_run_with_no_result_from_the_driver_puts_false_in_it
    o = create_query
    stub_db( o, FakeDb.new( [], nil ) )
    put_sql 'SELECT * FROM x'
    o.msg_run
    assert_equal false, @engine.heap.it.value
  end

  #
  # run_query (used by table) returns nil when the query fails.
  #
  def test_run_query_returns_nil_on_a_database_error
    o = create_query
    stub_db( o, RaisingDb.new( FakeDbError.new( 'bad' ) ) )
    put_sql 'SELECT * FROM x'
    assert_nil o.run_query
    assert_equal 'Query failed: bad', @engine.heap.error.value
  end

  def test_run_query_returns_the_raw_result_from_the_db
    o = create_query
    fake_db = FakeDb.new( [ 'id', 'name' ], [ [ 1, 'Ann' ] ] )
    stub_db( o, fake_db )

    i = @engine.parser.parse_immediate "put 'SELECT * FROM x' into o.sql"
    i.run

    result = o.run_query
    assert_equal [ [ 1, 'Ann' ] ], result
    assert_equal 'SELECT * FROM x', fake_db.last_sql
  end

  def test_msg_run_populates_the_result_container_with_rows
    o = create_query
    fake_db = FakeDb.new( [ 'id', 'name' ], [ [ 1, 'Ann' ], [ 2, 'Bo' ] ] )
    stub_db( o, fake_db )

    i = @engine.parser.parse_immediate "put 'SELECT * FROM x' into o.sql"
    i.run

    o.msg_run

    result = o.find_child( 'result' )
    assert_equal 2, result.child_count
    assert_equal 1, result.children[ 0 ].find_child( 'id' ).value
    assert_equal 'Ann', result.children[ 0 ].find_child( 'name' ).value
  end

  #
  # A single-row result maps values onto children that already exist
  # in the result container (a "form" style) - unlike the multi-row
  # case, update_single_row does not create children on the fly.
  #
  def test_msg_run_populates_the_result_container_for_a_single_row
    o = create_query
    fake_db = FakeDb.new( [ 'id', 'name' ], [ [ 1, 'Ann' ] ] )
    stub_db( o, fake_db )

    i = @engine.parser.parse_immediate "put 'SELECT * FROM x' into o.sql"
    i.run
    i = @engine.parser.parse_immediate 'create o.result.id as untyped'
    i.run
    i = @engine.parser.parse_immediate 'create o.result.name as string'
    i.run

    o.msg_run

    result = o.find_child( 'result' )
    assert_equal 1, result.find_child( 'id' ).value
    assert_equal 'Ann', result.find_child( 'name' ).value
  end

  def test_msg_run_clears_stale_results_before_running_again
    o = create_query
    stub_db( o, FakeDb.new( [ 'id' ], [ [ 1 ], [ 2 ] ] ) )
    i = @engine.parser.parse_immediate "put 'SELECT * FROM x' into o.sql"
    i.run
    o.msg_run
    assert_equal 2, o.find_child( 'result' ).child_count

    # Next run returns no rows - the old rows must not linger.
    stub_db( o, FakeDb.new( [], [] ) )
    o.msg_run
    assert_equal 0, o.find_child( 'result' ).child_count
  end

  def test_param_array_reads_sql_values_from_the_params_container
    o = create_query
    fake_db = FakeDb.new( [], [] )
    stub_db( o, fake_db )

    i = @engine.parser.parse_immediate 'create o.params as can'
    i.run
    i = @engine.parser.parse_immediate 'create o.params.a as string : one'
    i.run
    i = @engine.parser.parse_immediate 'create o.params.b as integer : 2'
    i.run
    i = @engine.parser.parse_immediate "put 'SELECT ?, ?' into o.sql"
    i.run

    o.msg_run

    assert_equal [ 'one', 2 ], fake_db.last_params
  end

  def test_param_array_is_nil_when_the_params_container_is_empty
    o = create_query
    fake_db = FakeDb.new( [], [] )
    stub_db( o, fake_db )

    i = @engine.parser.parse_immediate 'create o.params as can'
    i.run
    i = @engine.parser.parse_immediate "put 'SELECT 1' into o.sql"
    i.run

    o.msg_run

    assert_nil fake_db.last_params
  end

  def test_simple_list_defaults_to_false
    o = create_query
    refute o.simple_list?
  end

end