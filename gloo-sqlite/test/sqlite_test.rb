require 'test_helper'
require 'minitest/mock'
require 'tmpdir'

class SqliteTest < BaseEngineTest

  def test_the_typename
    assert_equal 'sqlite', Sqlite.typename
  end

  def test_the_short_typename
    assert_equal 'sqlite', Sqlite.short_typename
  end

  def test_doc_data
    data = Sqlite.doc_data
    assert_equal Sqlite.typename, data[ :name ]
    assert_equal Sqlite.short_typename, data[ :shortcut ]
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
    assert_equal "Could not connect to sqlite 'o': file is not a database", @engine.heap.error.value
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

  #
  # verify with no database child is a setup error, not a crash.
  #
  def test_verify_with_no_database_child_is_an_error
    obj = Sqlite.new( @engine )
    obj.name = 'o'
    obj.msg_verify
    assert_equal Sqlite::DB_REQUIRED_ERR, @engine.heap.error.value
    assert_equal false, @engine.heap.it.value
  end

  #
  # query with no database name reports a setup error and returns no
  # result (so Query treats it as a failure).
  #
  def test_query_with_no_database_name_returns_no_result
    obj = build_sqlite_obj( '' )
    assert_nil obj.query( 'SELECT 1' )
    assert_equal Sqlite::DB_REQUIRED_ERR, @engine.heap.error.value
  end

  #
  # Bad SQL comes out of the driver as a database error, for Query
  # to report.
  #
  def test_query_with_bad_sql_raises_a_database_error
    Dir.mktmpdir do |dir|
      obj = build_sqlite_obj( File.join( dir, 'bad.db' ) )
      error = assert_raises( SQLite3::Exception ) { obj.query( 'SELEC nope' ) }
      assert obj.database_errors.any? { |c| error.is_a?( c ) }
    end
  end

  #
  # The database is closed after each query, and after a failed one.
  #
  def test_query_closes_the_database
    Dir.mktmpdir do |dir|
      path = File.join( dir, 'close.db' )
      obj = build_sqlite_obj( path )
      db = SQLite3::Database.open( path )
      SQLite3::Database.stub( :open, db ) { obj.query( 'SELECT 1' ) }
      assert db.closed?

      db2 = SQLite3::Database.open( path )
      SQLite3::Database.stub( :open, db2 ) do
        assert_raises( SQLite3::Exception ) { obj.query( 'SELEC nope' ) }
      end
      assert db2.closed?
    end
  end

  #
  # Set up a query object (q) on the sqlite connection (o) with the
  # given SQL.
  #
  def build_query( path, sql )
    build_sqlite_obj( path )
    @engine.parser.run 'create q as query'
    @engine.parser.run "put 'o' into q.database*"
    @engine.parser.run "put '#{sql}' into q.sql"
    return @engine.heap.root.find_child( 'q' )
  end

  #
  # Through gloo-db's query: a query that works puts true in it.
  #
  def test_query_run_puts_true_in_it
    Dir.mktmpdir do |dir|
      build_query( File.join( dir, 'run.db' ), 'CREATE TABLE t ( id INTEGER )' )
      @engine.parser.run 'tell q to run'
      assert_equal true, @engine.heap.it.value
      refute @engine.error?
    end
  end

  #
  # Through gloo-db's query: bad SQL is one readable error, and it is
  # false.
  #
  def test_query_run_with_bad_sql_is_a_readable_error
    Dir.mktmpdir do |dir|
      build_query( File.join( dir, 'run2.db' ), 'SELECT * FROM nope' )
      @engine.parser.run 'tell q to run'
      assert_equal 'Query failed: no such table: nope', @engine.heap.error.value
      assert_equal false, @engine.heap.it.value
    end
  end

end
