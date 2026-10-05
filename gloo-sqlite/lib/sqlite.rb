# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2020 Eric Crane.  All rights reserved.
#
# A Sqlite3 database connection.
#
# https://www.rubydoc.info/gems/sqlite3/1.3.11
# https://www.devdungeon.com/content/ruby-sqlite-tutorial
#
# db.results_as_hash = true
#   Set results to return as Hash object.
#   This is slower but offers a huge convenience.
#   Consider turning it off for high performance situations.
#   Each row will have the column name as the hash key.
#
# # Alternatively, to only get one row and discard the rest,
# replace `db.query()` with `db.get_first_value()`.
#
require 'sqlite3'
require 'db_connection'

class Sqlite < Gloo::Core::Obj

  # Shared driver behaviour from gloo-db: errors, verify, setup problems.
  include DbConnection

  KEYWORD = 'sqlite'.freeze
  KEYWORD_SHORT = 'sqlite'.freeze

  DB = 'database'.freeze
  DEFAULT_DB = 'test.db'.freeze

  DB_REQUIRED_ERR = 'The database name is required!'.freeze
  DB_NOT_FOUND_ERR = 'The database file was not found!'.freeze

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

  #
  # Does this object have children to add when an object
  # is created in interactive mode?
  # This does not apply during obj load, etc.
  #
  def add_children_on_create?
    return true
  end

  #
  # Add children to this object.
  # This is used by containers to add children needed
  # for default configurations.
  #
  def add_default_children
    fac = @engine.factory
    fac.create_string DB, DEFAULT_DB, self
  end

  # ---------------------------------------------------------------------
  #    Messages
  # ---------------------------------------------------------------------

  #
  # Get a list of message names that this object receives.
  #
  def self.messages
    return super + [ 'verify' ]
  end

  #
  # Verify access to the Sqlite database specified.
  #
  def msg_verify
    name = db_value
    if name.empty?
      @engine.err DB_REQUIRED_ERR
      @engine.heap.it.set_to false
      return
    end

    unless File.exist? name
      @engine.err DB_NOT_FOUND_ERR
      @engine.heap.it.set_to false
      return
    end

    verify_connection do
      db = SQLite3::Database.open name
      begin
        db.get_first_value "SELECT COUNT(name) FROM sqlite_master WHERE type='table'"
      ensure
        db.close
      end
    end
  end

  #
  # The exception classes that are database errors (DbConnection):
  # Query reports these as 'Query failed: …'.
  #
  def database_errors
    return [ SQLite3::Exception ]
  end

  # ---------------------------------------------------------------------
  #    DB functions (all database connections)
  # ---------------------------------------------------------------------

  #
  # Open a connection and execute the SQL statement.
  # Return the resulting data.
  #
  def query( sql, params = nil )
    name = db_value
    return setup_err( DB_REQUIRED_ERR ) if name.empty?

    # A database file that doesn't exist is created.
    db = SQLite3::Database.open name
    begin
      results = db.query( sql, params )

      rows = []
      while ( row = results.next ) do
        rows << row
      end

      # Return [ column names, rows ] - the same shape as gloo-mysql and
      # gloo-pg, so callers (Query, Table) can treat every backend alike.
      return [ results.columns, rows ]
    ensure
      results&.close
      db.close
    end
  end

  #
  # Based on the result set, build a QueryResult object.
  #
  def get_query_result( result )
    return QueryResult.new( result[0], result[1], @engine )
  end


  # ---------------------------------------------------------------------
  #    Private functions
  # ---------------------------------------------------------------------

  private

  #
  # Get the Database file from the child object.
  # Returns '' if there is none.
  #
  def db_value
    o = find_child DB
    return '' unless o

    return o.value.to_s
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
      :shortcut => KEYWORD_SHORT,
      :description => 'A Sqlite3 database connection.',
      :children => [
        "database (string) — Default: '#{DEFAULT_DB}'. The path to the database file. A query on a file that does not exist creates a new, empty database there."
      ],
      :messages => [
        'verify — Verify that the database connection can be established. It is true if it can, false if not: no database name, a file that does not exist, or a file that is not a database (with the reason in the error).'
      ],
      :examples => <<~EXAMPLES.strip
        sqlite [can] :
          on_load [script] : run sqlite.sql
          db [sqlite] :
            database : test.db
          sql [query] :
            database [alias] : sqlite.db
            sql : SELECT id, key, value FROM key_values
      EXAMPLES
    }
  end

end
