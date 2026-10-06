require 'test_helper'

class ColorizeTest < BaseEngineTest

  def test_the_typename
    assert_equal 'colorize', CliColorize.typename
  end

  def test_the_short_typename
    assert_equal 'color', CliColorize.short_typename
  end

  def test_doc_data
    data = CliColorize.doc_data
    assert_equal CliColorize.typename, data[ :name ]
    assert_equal CliColorize.short_typename, data[ :shortcut ]
  end

  def test_find_type
    assert @dic.find_obj( 'colorize' )
    assert @dic.find_obj( 'color' )
  end

  def test_messages
    msgs = CliColorize.messages
    assert msgs
    assert msgs.include?( 'run' )
    assert msgs.include?( 'unload' )
  end

  def test_adds_children_on_create
    o = CliColorize.new( @engine )
    assert o.add_children_on_create?
  end

  #
  # Run a line of gloo.
  #
  def run_cmd( cmd )
    @engine.parser.parse_immediate( cmd ).run
  end

  #
  # A known color colors its text; the line is in it.
  #
  def test_run_colors_known_colors
    run_cmd 'create c as colorize'
    run_cmd "put 'hi' into c.white"

    warnings = capture_warnings { capture_io { run_cmd 'tell c to run' } }
    assert_empty warnings
    assert_equal ColorizedString[ 'hi' ].colorize( :white ), @engine.heap.it.value
  end

  #
  # An unknown color is a warning, and its text is shown uncolored.
  #
  def test_run_warns_on_an_unknown_color
    run_cmd 'create c as colorize'
    run_cmd 'create c.bogus as string : plain'

    warnings = capture_warnings { capture_io { run_cmd 'tell c to run' } }
    assert_equal [ "Unknown color 'bogus' in colorize 'c'; shown uncolored." ], warnings
    assert @engine.heap.it.value.end_with?( 'plain' )
  end

end
