# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
require 'test_helper'

class BeepTest < BaseEngineTest

  def test_the_keyword
    assert_equal 'beep', Beep.keyword
  end

  def test_the_keyword_shortcut
    assert_equal 'b', Beep.keyword_shortcut
  end

  def test_run_sets_it_and_prints_the_bell_character
    v = @engine.parser.parse_immediate 'beep'
    out, _err = capture_io { v.run }

    assert_equal 'beep', @engine.heap.it.value
    assert_equal 7.chr, out
  end

end
