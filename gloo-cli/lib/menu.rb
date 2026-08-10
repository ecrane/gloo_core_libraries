# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2020 Eric Crane.  All rights reserved.
#
# A CLI menu.
# The menu contains a collection of menu items, a prompt
# and an option to loop until done.
#

class Menu < Gloo::Core::Obj

  KEYWORD = 'menu'.freeze
  KEYWORD_SHORT = 'menu'.freeze
  PROMPT = 'prompt'.freeze
  ITEMS = 'items'.freeze
  LOOP = 'loop'.freeze
  HIDE_ITEMS = 'hide_items'.freeze
  BEFORE_MENU = 'before_menu'.freeze
  DEFAULT = 'default'.freeze
  TITLE = 'title'.freeze
  TITLE_COLOR = 'green'.freeze
  QUIT_ITEM_NAME = 'q'.freeze

  @@menu_stack = []

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

  #
  # Get the value of the prompt child object.
  # Returns nil if there is none.
  #
  def prompt_value
    o = find_child PROMPT
    return '' unless o

    return o.value
  end

  #
  # Get the value of the loop child object.
  # Should we keep looping or should we stop?
  #
  def loop?
    return false unless @engine.running

    o = find_child LOOP
    return false unless o

    return o.value
  end

  # 
  # If there is no loop child, add it.
  # 
  def add_loop_child
    o = find_child LOOP
    if o
      o.set_value true
      return 
    end

    fac = @engine.factory
    fac.create_bool LOOP, true, self
  end

  # 
  # Add a Quit menu item
  # 
  def add_quit_item
    items = find_child ITEMS
    q = items.find_child QUIT_ITEM_NAME
    return if q

    fac = @engine.factory
    fac.create_bool LOOP, true, self

    params = { :name => QUIT_ITEM_NAME,
      :type => 'mitem',
      :value => 'Quit',
      :parent => items }
    mitem = fac.create params
    script = "put false into #{self.pn}.loop"
    fac.create_script 'do', script, mitem
  end

  # 
  # Add any required children not specified in the source.
  # 
  def lazy_add_children
    add_loop_child
    add_quit_item
  end

  #
  # Does the menu have a title?
  #
  def title?
    o = find_child TITLE
    return o ? true : false
  end

  #
  # Get the Menu's Title.
  #
  def title
    obj = find_child TITLE
    return obj.value
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
    fac.create_string PROMPT, '> ', self
    fac.create_can ITEMS, self
    fac.create_bool LOOP, true, self
    fac.create_script DEFAULT, '', self
  end

  # ---------------------------------------------------------------------
  #    Menu Stack
  # ---------------------------------------------------------------------

  # 
  # Show the bread-crumbs for the menu stack.
  # 
  def show_menu_stack
    if @@menu_stack.count < 2
      puts '...'
    else
      msg = ''
      @@menu_stack[0..-2].each do |menu|
        msg << ' | ' unless msg.blank?
        msg << menu.title
      end
      msg << ' | ... '
      puts msg
    end
  end

  # 
  # Add a menu to the stack.
  # 
  def push_menu obj
    @@menu_stack << obj
  end

  # 
  # Pop a menu from the stack.
  # If the last item isn't the given menu,
  # it won't be popped.
  # 
  def pop_menu menu
    if @@menu_stack[-1] == menu
      @@menu_stack.pop
    end
  end

  # 
  # Quit all menus and drop into gloo.
  # 
  def pop_to_top_level_menu
    @engine.log.debug 'Quitting to top level menu'
    while @@menu_stack.count > 1
      menu = @@menu_stack.pop
      o = menu.find_child LOOP
      o.set_value( false ) if o
    end
  end

  # 
  # Quit all menus and drop into gloo.
  # 
  def quit_all_menus
    @engine.log.debug 'Dropping into Gloo'
    @@menu_stack.each do |menu|
      o = menu.find_child LOOP
      o.set_value( false ) if o
    end
    @engine.loop
  end

  # ---------------------------------------------------------------------
  #    Messages
  # ---------------------------------------------------------------------

  #
  # Get a list of message names that this object receives.
  #
  def self.messages
    return super + [ 'run' ]
  end

  #
  # Show the menu options, and prompt for user input.
  #
  def msg_run
    lazy_add_children
    push_menu self
    run_default
    loop do
      begin_menu
      if prompt_value.empty?
        dt = DateTime.now
        d = dt.strftime( '%Y.%m.%d' )
        t = dt.strftime( '%I:%M:%S' )
        theme = @engine.theme
        cmd = @engine.platform.prompt.ask( "#{theme.accent( d )} #{theme.emphasis( t )} >" )
      else
        cmd = @engine.platform.prompt.ask( prompt_value )
      end
      cmd ? run_command( cmd ) : run_default
      break unless loop?
    end
    pop_menu self
  end

  # ---------------------------------------------------------------------
  #    Menu actions
  # ---------------------------------------------------------------------

  #
  # Begin the menu execution.
  # Run the before menu script if there is one,
  # then show options unless we are hiding them by default.
  #
  def begin_menu
    run_before_menu

    # Check to see if we should show items at all.
    o = find_child HIDE_ITEMS
    return if o && o.value == true

    show_options
  end

  #
  # If there is a before menu script, run it now.
  #
  def run_before_menu
    o = find_child BEFORE_MENU
    return unless o

    Gloo::Exec::Dispatch.message( @engine, 'run', o )
  end

  #
  # Show the list of menu options.
  #
  def show_options
    o = find_child ITEMS
    return unless o

    o.children.each do |mitem|
      mitem = Gloo::Objs::Alias.resolve_alias( @engine, mitem )
      puts "  #{mitem.shortcut_value} - #{mitem.description_value}"
    end
  end

  #
  # Find the command matching user input.
  #
  def find_cmd( cmd )
    o = find_child ITEMS
    return nil unless o

    o.children.each do |mitem|
      mitem = Gloo::Objs::Alias.resolve_alias( @engine, mitem )
      return mitem if mitem.shortcut_value.downcase == cmd.downcase
    end

    return nil
  end

  #
  # Run the default option.
  #
  def run_default
    obj = find_child DEFAULT
    if obj
      s = Gloo::Exec::Script.new( @engine, obj )
      s.run
    elsif title?
      run_default_title
    end
  end

  #
  # There is a title, so show it.
  #
  # Deliberately left uncolored, same reasoning as
  # Gloo::App::Table#show: box-drawing borders and text read fine
  # against the terminal's own default colors, and forcing a fixed
  # foreground/background fights whatever theme the terminal is
  # actually running.
  #
  def run_default_title
    @engine.platform&.clear_screen
    show_menu_stack

    puts @engine.platform.table.box( title )
  end

  #
  # Run the selected command.
  #
  def run_command( cmd )
    @engine.log.info "Menu Command: #{cmd}"
    obj = find_cmd cmd

    if obj
      script = obj.do_script
      return unless script

      s = Gloo::Exec::Script.new( @engine, script )
      s.run
    else
      if cmd == '?'
        @engine.log.debug 'Showing options'
        show_options
      elsif cmd == 'q!'
        @engine.log.debug 'Quitting Gloo'
        @engine.stop_running
      elsif cmd == 'qq'
        @engine.log.debug 'Quitting to top level menu'
        pop_to_top_level_menu
      elsif cmd.starts_with? ':'
        gloo_cmd = cmd[1..-1].strip
        if gloo_cmd.blank?
          @engine.log.debug 'Quitting all menus and dropping into Gloo'
          quit_all_menus
        else
          @engine.log.debug "Running Gloo command: #{gloo_cmd}"
          @engine.process_cmd gloo_cmd
        end
      else
        msg = "#{cmd} is not a valid option"
        @engine.log.warn msg
      end
      return
    end

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
      :description => 'A CLI menu. This can be used for the main loop ' \
        'of a CLI application. Many of the children are optional; some ' \
        'will be created dynamically if they are not specified in the ' \
        'source file. Note that a Quit menu item will be added ' \
        'dynamically if one is not specified in the source file.',
      :children => [
        "prompt (string) — Default: '> '. Optional; if not provided a default timestamp option is used. The prompt shown for menu item selection.",
        'items (container) — The list of menu items.',
        'loop (boolean) — Run the menu in a loop? If true, once a menu item has run, the menu prompts again; setting it to false ends the menu. Created dynamically if not specified.',
        'title (string) — Optional title to use rather than manually implementing a menu header. With a title, the default and before_menu items are not needed.',
        'hide_items (boolean) — Optional, false by default. If false, the menu items are shown each time through the loop; if true, they\'re hidden (can always be shown by typing ? at the prompt).',
        'default (script) — Optional. Run if no other option is selected (RETURN pressed). Can be used to clear the screen, for example.',
        'before_menu (script) — Optional. Run at the top of each loop through the menu.'
      ],
      :messages => [
        'run — Show the options and the prompt, then run the script for the user\'s selection. Optionally repeat as long as the loop child is true.'
      ],
      :notes => 'Built-in menu items, always available: q — quit this ' \
        'menu (quits the app if this is the root menu, or goes up to ' \
        'the prior menu if a sub-menu); qq — quit to the top level ' \
        'menu (not shown); q! — quit gloo entirely (not shown); ' \
        ': {command} — run a gloo command not part of the running app; ' \
        ': (alone) — quit the running app and drop into gloo, keeping ' \
        'loaded app objects in the stack.',
      :examples => <<~EXAMPLES.strip
        simple [menu] :
          on_load [script] :
            run simple
          title [string] : Simple Menu
          items [can] :
            h [mitem] : Run Hello World
              do [script] : show 'Hello World!'

        menu [menu] :
          on_load [script] :
            run menu
          prompt [string] : >
          loop [bool] : true
          items [can] :
            hw [mitem] :
              shortcut [str] : hw
              description [str] : Run Hello World
              do [script] :
                show 'Hello World!'
            q [mitem] :
              shortcut [str] : q
              description [str] : Quit this menu
              do [script] :
                put false into menu.loop
      EXAMPLES
    }
  end

end
