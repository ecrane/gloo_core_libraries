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

class QueryTest < BaseEngineTest

  def test_the_typename
    assert_equal 'query', Query.typename
  end

  def test_the_short_typename
    assert_equal 'sql', Query.short_typename
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

  def test_msg_run_with_no_database_child_reports_an_error_and_does_not_raise
    o = create_query
    o.msg_run # should not raise
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