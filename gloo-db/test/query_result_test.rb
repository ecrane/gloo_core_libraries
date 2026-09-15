require 'test_helper'

class QueryResultTest < BaseEngineTest

  def test_the_single_row_count
    h = []
    d = [ [ 1 ] ]
    o = QueryResult.new( h, d )

    assert o
    assert o.single_row_result?

    d = []
    o = QueryResult.new( h, d )
    refute o.single_row_result?

    d = [ [ 1 ], [ 2 ] ]
    o = QueryResult.new( h, d )
  end

  def test_data_to_show
    o = QueryResult.new( nil, nil )
    refute o.has_data_to_show?

    o = QueryResult.new( [], [] )
    refute o.has_data_to_show?

    o = QueryResult.new( nil, [] )
    refute o.has_data_to_show?

    o = QueryResult.new( [], nil )
    refute o.has_data_to_show?

    o = QueryResult.new( [ 1 ], [] )
    refute o.has_data_to_show?

    o = QueryResult.new( nil, [ 1 ] )
    refute o.has_data_to_show?

    o = QueryResult.new( nil, [] )
    refute o.has_data_to_show?

    d = [ [ 1 ], [ 2 ] ]
    o = QueryResult.new( [ 1 ], d )
    assert o.has_data_to_show?
  end

  def create_can( pn )
    i = @engine.parser.parse_immediate "create #{pn} as can"
    i.run
    return @engine.heap.root.find_child( pn )
  end

  #
  # update_single_row only maps values onto children that already
  # exist in the container - it does not create new ones. Different
  # from update_rows below; see the equivalent note on the Query
  # single-row test.
  #
  def test_update_result_container_single_row_maps_onto_existing_children
    can = create_can( 'result1' )
    i = @engine.parser.parse_immediate 'create result1.id as untyped'
    i.run
    i = @engine.parser.parse_immediate 'create result1.name as string'
    i.run

    o = QueryResult.new( [ 'id', 'name' ], [ [ 1, 'Ann' ] ] )
    o.update_result_container( can )

    assert_equal 1, can.find_child( 'id' ).value
    assert_equal 'Ann', can.find_child( 'name' ).value
  end

  def test_update_result_container_multi_row_creates_a_container_per_row
    can = create_can( 'result2' )

    o = QueryResult.new( [ 'id', 'name' ], [ [ 1, 'Ann' ], [ 2, 'Bo' ] ] )
    o.update_result_container( can )

    assert_equal 2, can.child_count
    assert_equal 1, can.children[ 0 ].find_child( 'id' ).value
    assert_equal 'Bo', can.children[ 1 ].find_child( 'name' ).value
  end

  def test_update_result_container_simple_flattens_multi_row_values
    can = create_can( 'result3' )

    o = QueryResult.new( [ 'name' ], [ [ 'Ann' ], [ 'Bo' ] ] )
    o.update_result_container_simple( can )

    values = can.children.map( &:name )
    assert_equal [ 'Ann', 'Bo' ], values
  end

  def test_show_does_not_raise_for_a_single_row
    o = QueryResult.new( [ 'id' ], [ [ 1 ] ], @engine )
    capture_io { o.show } # should not raise
  end

  def test_show_does_not_raise_for_multiple_rows
    o = QueryResult.new( [ 'id' ], [ [ 1 ], [ 2 ] ], @engine )
    capture_io { o.show } # should not raise
  end

end