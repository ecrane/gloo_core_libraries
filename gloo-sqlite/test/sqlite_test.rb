require 'test_helper'
require 'tmpdir'

class SqliteTest < BaseEngineTest

  def test_the_typename
    assert_equal 'sqlite', Sqlite.typename
  end

  def test_the_short_typename
    assert_equal 'sqlite', Sqlite.short_typename
  end

  def test_find_type
    assert @dic.find_obj( 'sqlite' )
    assert @dic.find_obj( 'SQLITE' )
    assert @dic.find_obj( 'Sqlite' )
  end

  def test_messages
    msgs = Sqlite.messages
    assert msgs
    assert msgs.include?( 'verify' )
    assert msgs.include?( 'unload' )
  end

  def test_adds_children_on_create
    o = Sqlite.new( @engine )
    assert o.add_children_on_create?
  end

  def test_that_children_are_added_on_create
    @engine.parser.run 'create o as sqlite'
    assert_equal 1, @engine.heap.root.child_count
    obj = @engine.heap.root.children.first
    assert obj
    assert_equal 'o', obj.name
    assert_equal 1, obj.child_count
    assert_equal 'database', obj.children.first.name
  end

  def test_that_db_required_to_verify
    @engine.parser.run 'create o as sqlite'
    assert_equal 1, @engine.heap.root.child_count
    obj = @engine.heap.root.children.first
    assert obj
    @engine.parser.run "put '' into o.database"
    assert_equal '', obj.children.first.value
    @engine.parser.run "tell o to verify"
    assert_equal false, @engine.heap.it.value
    assert @engine.error?
    assert_equal Sqlite::DB_REQUIRED_ERR, @engine.heap.error.value
  end

  def test_that_db_file_is_verified
    @engine.parser.run 'create o as sqlite'
    assert_equal 1, @engine.heap.root.child_count
    obj = @engine.heap.root.children.first
    assert obj
    @engine.parser.run "put 'test/test.xyz' into o.database"
    @engine.parser.run "tell o to verify"
    assert_equal false, @engine.heap.it.value
    assert @engine.error?
    assert_equal Sqlite::DB_NOT_FOUND_ERR, @engine.heap.error.value
  end

  def test_opening_file_that_isnt_sqlite_db
    @engine.parser.run 'create o as sqlite'
    assert_equal 1, @engine.heap.root.child_count
    obj = @engine.heap.root.children.first
    assert obj
    @engine.parser.run "put 'test/test_helper.rb' into o.database"
    @engine.parser.run "tell o to verify"
    assert @engine.error?
    assert_equal 'file is not a database', @engine.heap.error.value
    assert_equal false, @engine.heap.it.value
  end

  #
  # 'test/test.db' - a fixture this test relied on - never actually
  # existed in this gem's test/ dir, so this test could only ever
  # have failed. Build a real, valid, throwaway SQLite file instead
  # of committing a binary fixture to git.
  #
  def test_verify_for_a_real_db_file
    Dir.mktmpdir do |dir|
      path = File.join( dir, 'real.db' )
      SQLite3::Database.open( path ).close

      @engine.parser.run 'create o as sqlite'
      obj = @engine.heap.root.children.first
      @engine.parser.run "put '#{path}' into o.database"
      @engine.parser.run "tell o to verify"
      assert_equal true, @engine.heap.it.value
    end
  end

  #
  # #query and #get_query_result are the actual driver contract that
  # Query/Table (gloo-db) depend on - already covered end-to-end at
  # the .gloo layer via a real round trip, but worth pinning directly
  # in Ruby too since this is the one piece that's genuinely specific
  # to this gem rather than shared orchestration logic.
  #
  def build_sqlite_obj( path )
    @engine.parser.run 'create o as sqlite'
    obj = @engine.heap.root.children.first
    @engine.parser.run "put '#{path}' into o.database"
    return obj
  end

  def test_query_returns_columns_and_rows_in_the_shared_shape
    Dir.mktmpdir do |dir|
      path = File.join( dir, 'q.db' )
      db = SQLite3::Database.open( path )
      db.execute( 'CREATE TABLE t ( id INTEGER, name TEXT )' )
      db.execute( 'INSERT INTO t (id, name) VALUES (1, ?)', [ 'Ann' ] )
      db.execute( 'INSERT INTO t (id, name) VALUES (2, ?)', [ 'Bo' ] )
      db.close

      obj = build_sqlite_obj( path )
      columns, rows = obj.query( 'SELECT id, name FROM t ORDER BY id' )

      assert_equal [ 'id', 'name' ], columns
      assert_equal [ [ 1, 'Ann' ], [ 2, 'Bo' ] ], rows
    end
  end

  def test_query_accepts_bound_parameters
    Dir.mktmpdir do |dir|
      path = File.join( dir, 'q2.db' )
      db = SQLite3::Database.open( path )
      db.execute( 'CREATE TABLE t ( name TEXT )' )
      db.execute( "INSERT INTO t (name) VALUES ('alpha')" )
      db.execute( "INSERT INTO t (name) VALUES ('beta')" )
      db.close

      obj = build_sqlite_obj( path )
      _columns, rows = obj.query( 'SELECT name FROM t WHERE name = ?', [ 'beta' ] )

      assert_equal [ [ 'beta' ] ], rows
    end
  end

  def test_get_query_result_builds_a_query_result_from_the_query_shape
    obj = Sqlite.new( @engine )
    result = obj.get_query_result( [ [ 'id' ], [ [ 1 ], [ 2 ] ] ] )

    assert_kind_of QueryResult, result
    assert result.has_data_to_show?
  end

end
