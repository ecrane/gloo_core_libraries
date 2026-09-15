require 'test_helper'

class TableTest < BaseEngineTest

  def test_the_typename
    assert_equal 'table', Table.typename
  end

  def test_the_short_typename
    assert_equal 'tbl', Table.short_typename
  end

  def test_find_type
    assert @dic.find_obj( 'table' )
    assert @dic.find_obj( 'tbl' )
  end

  def test_messages
    msgs = Table.messages
    assert msgs
    assert msgs.include?( 'show' )
  end

  def test_adds_children_on_create
    o = Table.new @engine
    assert o.add_children_on_create?
  end

  def test_that_children_are_added_on_create
    i = @engine.parser.parse_immediate 'create o as tbl'
    i.run
    assert_equal 1, @engine.heap.root.child_count
    obj = @engine.heap.root.children.first
    assert obj
    assert_equal 'o', obj.name
    assert_equal 2, obj.child_count
    assert_equal 'headers', obj.children.first.name
    assert_equal 'data', obj.children.last.name
  end

  def create_table
    i = @engine.parser.parse_immediate 'create t as tbl'
    i.run
    return @engine.heap.root.find_child( 't' )
  end

  def add_header( t, key, title )
    i = @engine.parser.parse_immediate "create t.headers.#{key} as string : #{title}"
    i.run
  end

  def test_headers_returns_display_titles_and_columns_returns_keys
    t = create_table
    add_header( t, 'name', 'Name' )
    add_header( t, 'phone', 'Phone' )

    assert_equal [ 'Name', 'Phone' ], t.headers
    assert_equal [ 'name', 'phone' ], t.columns
  end

  def test_headers_and_columns_are_empty_without_a_headers_child
    o = Table.new( @engine )
    assert_equal [], o.headers
    assert_equal [], o.columns
  end

  #
  # data with a plain container (not a query) reads its rows from
  # whatever the 'data' child resolves to - a table doesn't need a
  # database at all when its data comes from ordinary gloo objects.
  # gloo-db has no driver of its own to test the Query-backed path
  # against; see query_test.rb's FakeDb for that side of Table#data.
  #
  def test_data_reads_multiple_rows_from_a_container_of_containers
    t = create_table
    add_header( t, 'name', 'Name' )
    add_header( t, 'phone', 'Phone' )

    i = @engine.parser.parse_immediate 'create t.data.r1 as can'
    i.run
    i = @engine.parser.parse_immediate 'create t.data.r1.name as string : Joe'
    i.run
    i = @engine.parser.parse_immediate 'create t.data.r1.phone as string : 555-1212'
    i.run

    cols, rows = t.data
    assert_equal [ 'name', 'phone' ], cols
    assert_equal [ [ 'Joe', '555-1212' ] ], rows
  end

  def test_data_reads_a_single_row_directly_from_the_data_container
    t = create_table
    add_header( t, 'name', 'Name' )
    add_header( t, 'phone', 'Phone' )

    i = @engine.parser.parse_immediate 'create t.data.name as string : Joe'
    i.run
    i = @engine.parser.parse_immediate 'create t.data.phone as string : 555-1212'
    i.run

    cols, rows = t.data
    assert_equal [ [ 'Joe', '555-1212' ] ], rows
  end

  def test_always_rows_defaults_to_false
    t = create_table
    refute t.always_rows
  end

  def test_build_columns_marks_a_column_invisible_when_not_in_headers
    t = create_table
    add_header( t, 'name', 'Name' )
    # 'phone' is in the result data but has no matching header.

    columns = t.build_columns( [ 'name', 'phone' ] )

    name_col = columns.find { |c| c[ :name ] == 'name' }
    phone_col = columns.find { |c| c[ :name ] == 'phone' }
    assert name_col[ :visible ]
    refute phone_col[ :visible ]
  end

  #
  # render's helper (WebSvr::TableRenderer, from gloo-web) only comes
  # from @engine.running_app - not faked here, same reasoning as
  # gloo-web's own Partial/Page render tests. What's safe and real to
  # check: render degrades to nil rather than raising when there's no
  # running app - render_ƒ used to be a required argument msg_render
  # never actually passed (a real bug, fixed alongside this test; see
  # the story notes).
  #
  def test_render_returns_nil_without_a_running_app
    t = create_table
    refute @engine.app_running?
    assert_nil t.render
  end

end
