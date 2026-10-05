# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# Shared behaviour for database connection objects (gloo-sqlite,
# gloo-mysql, gloo-pg). A connection class includes this module so
# every driver reports problems the same way:
#
#   - Database errors (bad SQL, a missing table, a lost connection)
#     come out of the driver's query as exceptions; Query reports them
#     as one readable error. database_errors says which exception
#     classes those are.
#   - Setup problems the driver can see (eg. no database name) are
#     reported with setup_err, and the query returns no result.
#   - verify puts true in it, or reports a readable error and puts
#     false (verify_connection).
#
module DbConnection

  #
  # The exception classes that are database errors for this driver.
  # Query reports these as 'Query failed: …'; anything else is an
  # unexpected error. Drivers override this with their library's
  # error classes.
  #
  def database_errors
    return [ StandardError ]
  end

  #
  # Verify the connection: run the block, which connects (and raises
  # if it can't). It is true when it connects, false otherwise, with
  # a readable error and no backtrace.
  #
  def verify_connection
    yield
    @engine.heap.it.set_to true
    return true
  rescue *database_errors, SystemCallError => e
    @engine.err "Could not connect to #{connection_label}: #{e.message}"
    @engine.heap.it.set_to false
    return false
  end

  #
  # Report a setup problem (eg. no database name) and return nil,
  # meaning no result.
  #
  def setup_err( msg )
    @engine.err msg
    return nil
  end

  #
  # How the connection is named in messages, eg. sqlite 'db'.
  #
  def connection_label
    return "#{self.class.typename} '#{name}'"
  end

end
