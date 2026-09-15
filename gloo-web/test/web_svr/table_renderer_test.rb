# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# Only exercises rows with no :cell_renderer - a cell_renderer needs
# @engine.running_app.obj.embedded_renderer, which needs a running
# app. Not set up here (see ServerTest for why not).
#
require 'test_helper'

class TableRendererTest < BaseEngineTest

  def styles
    return { 'table' => 'tbl', 'thead' => 'thd', 'head_cell' => 'th', 'row' => 'tr', 'cell' => 'td' }
  end

  def columns
    return [
      { data_index: 0, title: 'Name', visible: true, cell_renderer: nil, name: :name },
      { data_index: 1, title: 'Age', visible: true, cell_renderer: nil, name: :age }
    ]
  end

  def test_no_data_found_when_rows_is_nil
    r = WebSvr::TableRenderer.new( @engine )
    result = r.data_to_table( { rows: nil } )
    assert_equal WebSvr::TableRenderer::NO_DATA_FOUND, result
  end

  def test_no_data_found_when_rows_is_empty
    r = WebSvr::TableRenderer.new( @engine )
    result = r.data_to_table( { rows: [] } )
    assert_equal WebSvr::TableRenderer::NO_DATA_FOUND, result
  end

  def test_single_row_uses_the_single_row_layout
    r = WebSvr::TableRenderer.new( @engine )
    result = r.data_to_table( { rows: [ [ 'Ann', 30 ] ], columns: columns, styles: styles } )

    assert_includes result, 'Ann'
    assert_includes result, '30'
    assert_includes result, "<th class='th'>Name</th>"
  end

  def test_always_rows_forces_the_multi_row_layout_even_for_one_row
    r = WebSvr::TableRenderer.new( @engine )
    result = r.data_to_table( { rows: [ [ 'Ann', 30 ] ], columns: columns, styles: styles, always_rows: true } )

    assert_includes result, '<thead'
    assert_includes result, 'Ann'
  end

  def test_multi_row_table_includes_a_row_per_record
    r = WebSvr::TableRenderer.new( @engine )
    rows = [ [ 'Ann', 30 ], [ 'Bo', 40 ] ]
    result = r.data_to_table( { rows: rows, columns: columns, styles: styles } )

    assert_includes result, 'Ann'
    assert_includes result, '30'
    assert_includes result, 'Bo'
    assert_includes result, '40'
    assert_equal 2, result.scan( '<tr' ).count - 1 # -1 for the header row's own <tr
  end

  def test_hidden_columns_are_skipped
    r = WebSvr::TableRenderer.new( @engine )
    cols = [
      { data_index: 0, title: 'Name', visible: true, cell_renderer: nil, name: :name },
      { data_index: 1, title: 'Secret', visible: false, cell_renderer: nil, name: :secret }
    ]
    result = r.data_to_table( { rows: [ [ 'Ann', 'hidden-value' ], [ 'Bo', 'hidden-value' ] ], columns: cols, styles: styles } )

    refute_includes result, 'Secret'
    refute_includes result, 'hidden-value'
  end

end
