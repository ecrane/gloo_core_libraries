# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
require 'test_helper'

class MarkdownExtTest < BaseEngineTest

  def test_render_extensions_returns_empty_string_for_nil
    assert_equal '', MarkdownExt.render_extensions( nil )
  end

  def test_render_extensions_passes_through_plain_text_unchanged
    text = "Just some text.\nWith two lines.\n"
    assert_equal text, MarkdownExt.render_extensions( text )
  end

  def test_render_note_block_produces_a_panel_with_the_secondary_style
    data = "[!NOTE] A Title\nSome note content.\n\nAfter text.\n"
    html = MarkdownExt.render_extensions( data )

    assert_includes html, 'gloo-panel-secondary'
    assert_includes html, 'A Title'
    assert_includes html, 'Some note content.'
    assert_includes html, 'After text.'
  end

  def test_render_info_block_produces_a_panel_with_the_primary_style
    data = "[!INFO] Heads up\nInfo body.\n\n"
    html = MarkdownExt.render_extensions( data )

    assert_includes html, 'gloo-panel-primary'
    assert_includes html, 'Heads up'
  end

  def test_render_check_block_produces_a_panel_with_the_success_style
    data = "[!CHECK] Done\nAll good.\n\n"
    html = MarkdownExt.render_extensions( data )

    assert_includes html, 'gloo-panel-success'
  end

  def test_render_idea_block_produces_a_panel_with_the_warning_style
    data = "[!IDEA] Think about this\nAn idea.\n\n"
    html = MarkdownExt.render_extensions( data )

    assert_includes html, 'gloo-panel-warning'
  end

  def test_render_quote_block_uses_the_quote_template_not_the_panel_template
    data = "[!QUOTE] Someone Famous\nA memorable line.\n\n"
    html = MarkdownExt.render_extensions( data )

    assert_includes html, 'gloo-quote-container'
    assert_includes html, 'Someone Famous'
    assert_includes html, 'A memorable line.'
    refute_includes html, 'gloo-panel'
  end

  def test_explicit_panel_style_is_used_over_the_default
    data = "[!PANEL DANGER] Careful\nThis is risky.\n\n"
    html = MarkdownExt.render_extensions( data )

    assert_includes html, 'gloo-panel-danger'
    assert_includes html, 'Careful'
  end

  def test_unknown_extension_is_dropped_and_reported
    data = "[!NOPE] Not a real extension\nSome content.\n\nAfter text.\n"

    out, _err = capture_io { @html = MarkdownExt.render_extensions( data ) }

    assert_includes out, 'ERROR'
    assert_includes @html, 'After text.'
    refute_includes @html, 'Not a real extension'
  end

  #
  # Documents current, possibly-surprising behavior rather than
  # asserting what "should" happen: an extension block with no
  # trailing blank line (i.e. it's the last thing in the source) is
  # silently dropped - #render_extensions only flushes a block when
  # it hits a following blank line, never at end-of-input. Worth a
  # second look, but not an obvious one-line fix, so left as-is here.
  #
  def test_an_extension_block_with_no_trailing_blank_line_is_silently_dropped
    data = "[!NOTE] Trailing\nThis note has no blank line after it.\n"
    html = MarkdownExt.render_extensions( data )

    assert_equal '', html
  end

end
