require 'test_helper'

class MenuTest < BaseEngineTest

  def test_the_typename
    assert_equal 'menu', Menu.typename
  end

  def test_the_short_typename
    assert_equal 'menu', Menu.short_typename
  end

  def test_doc_data
    data = Menu.doc_data
    assert_equal Menu.typename, data[ :name ]
    assert_equal Menu.short_typename, data[ :shortcut ]
  end

  def test_find_type
    assert @dic.find_obj( 'menu' )
  end

  def test_messages
    msgs = Menu.messages
    assert msgs
    assert msgs.include?( 'unload' )
    assert msgs.include?( 'run' )
  end

  def test_adds_children_on_create
    o = Menu.new( @engine )
    assert o.add_children_on_create?
  end

  def test_that_children_are_added_on_create
    i = @engine.parser.parse_immediate 'create o as menu'
    i.run
    assert_equal 1, @engine.heap.root.child_count
    obj = @engine.heap.root.children.first
    assert obj
    assert_equal 'o', obj.name
    assert_equal 4, obj.child_count
    assert_equal 'prompt', obj.children.first.name
    assert_equal 'items', obj.children[1].name
    assert_equal 'loop', obj.children[2].name
    assert_equal 'default', obj.children.last.name
  end

  def test_the_default_prompt_value
    i = @engine.parser.parse_immediate 'create o as menu'
    i.run
    assert_equal 1, @engine.heap.root.child_count
    obj = @engine.heap.root.children.first
    assert obj
    assert obj.loop?
    prompt = obj.children.first
    assert_equal '> ', prompt.value
  end

  def test_the_loop_default_value
    i = @engine.parser.parse_immediate 'create o as menu'
    i.run
    assert_equal 1, @engine.heap.root.child_count
    obj = @engine.heap.root.children.first
    assert obj
    assert obj.loop?
    loop = obj.children[2]
    assert_equal 'loop', loop.name
    assert_equal true, loop.value
  end

  # Ctrl-C at the menu's empty prompt: the hint, and the menu carries on.
  def test_ctrl_c_at_an_empty_prompt_shows_the_hint
    shown = run_menu_with( [ Interrupt, 'q' ], buffer: '' )
    assert_equal [ "Use 'q' to quit this menu." ], shown
  end

  # Ctrl-C during a menu item stops it and comes back to the menu.
  def test_ctrl_c_during_an_item_comes_back_to_the_menu
    warnings = capture_warnings do
      run_menu_with( [ 's', 'h', 'q' ], buffer: '', spin: true )
    end
    assert_equal 1, warnings.count { |w| w.start_with?( 'Stopped by Ctrl-C' ) }
    assert_equal 'hi', @engine.heap.root.find_child( 'm' ).find_child( 'said' ).value
  end

  private

  #
  # Make menu m (item s runs stopper, stopped by Ctrl-C if spin; h sets
  # said) and run it,
  # with the prompt answering each of the answers in turn (an exception
  # class is raised, as Ctrl-C raises Interrupt). Returns what was shown.
  #
  def run_menu_with( answers, buffer: '', spin: false )
    @engine.parser.run 'create m as menu'
    m = @engine.heap.root.find_child( 'm' )
    @engine.parser.run 'create m.said as string'
    @engine.parser.run 'create m.items.s as mitem'
    @engine.parser.run 'create m.stopper as script : "show 1"'
    @engine.parser.run "put 'run m.stopper' into m.items.s.do"
    @engine.parser.run "put 's' into m.items.s.shortcut"
    @engine.parser.run 'create m.items.h as mitem'
    @engine.parser.run "put 'h' into m.items.h.shortcut"
    @engine.parser.run %q(put "put 'hi' into m.said" into m.items.h.do)
    stopper = m.find_child( 'stopper' )
    stopper.define_singleton_method( :msg_run ) { raise Interrupt } if spin

    shown = []
    @engine.log.define_singleton_method( :show ) { |msg, *| shown << msg }
    prompt = @engine.platform.prompt
    prompt.define_singleton_method( :ask ) do |*|
      a = answers.shift
      a.is_a?( Class ) ? raise( a ) : a
    end
    prompt.define_singleton_method( :line_typed ) { buffer }
    # The menu lists its options on stdout each time round; keep the
    # test output clean.
    capture_io { m.msg_run }
    return shown
  ensure
    @engine.log.singleton_class.send( :remove_method, :show )
    %i[ ask line_typed ].each do |meth|
      prompt.singleton_class.send( :remove_method, meth ) if prompt.singleton_methods.include?( meth )
    end
  end

end
