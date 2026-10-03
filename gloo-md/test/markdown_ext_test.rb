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

  #
  # An unknown extension is kept as plain text, with a warning.
  #
  def test_unknown_extension_is_kept_as_plain_text_with_a_warning
    @engine.log.reset_counts
    data = "[!NOPE] Not a real extension\nSome content.\n\nAfter text.\n"
    html = MarkdownExt.render_extensions( data, @engine )

    assert_includes html, '[!NOPE] Not a real extension'
    assert_includes html, 'Some content.'
    assert_includes html, 'After text.'
    assert_equal 1, @engine.log.warning_count
    refute @engine.error?
  end

  #
  # Without an engine, an unknown extension is still kept as plain text.
  #
  def test_unknown_extension_without_an_engine_is_kept
    data = "[!NOPE] Not a real extension\n\n"
    assert_includes MarkdownExt.render_extensions( data ), 'Not a real extension'
  end

  #
  # A block that's the last thing in the data, with no blank line
  # after it, is still rendered.
  #
  def test_an_extension_block_at_the_end_is_rendered
    data = "[!NOTE] Trailing\nThis note has no blank line after it.\n"
    html = MarkdownExt.render_extensions( data )

    assert_includes html, 'gloo-panel-secondary'
    assert_includes html, 'This note has no blank line after it.'
  end

  #
  # A block that starts right after another, with no blank line
  # between, doesn't lose the first block.
  #
  def test_back_to_back_blocks_are_both_rendered
    data = "[!NOTE] First\nFirst body.\n[!INFO] Second\nSecond body.\n\n"
    html = MarkdownExt.render_extensions( data )

    assert_includes html, 'First body.'
    assert_includes html, 'Second body.'
  end

  #
  # An unknown block followed right away by a known one is kept apart
  # from it, so the known block's HTML isn't pulled into a paragraph.
  #
  def test_unknown_block_then_known_block_are_kept_apart
    data = "[!NOPE] x\nKept.\n[!NOTE] n\nNote body.\n\n"
    html = Md.md_2_html( MarkdownExt.render_extensions( data ) )

    refute_match( /<p>[^<]*Kept\.\s*<div/, html )
    assert_includes html, 'Note body.'
  end

  #
  # A badge (an image link, starting [![) is normal Markdown, not an
  # extension block: it renders with no warning.
  #
  def test_a_badge_line_is_not_an_extension
    @engine.log.reset_counts
    data = "[![Build](img.svg)](https://example.com)\nAfter the badge.\n"
    html = Md.md_2_html( MarkdownExt.render_extensions( data, @engine ) )

    assert_includes html, '<img src="img.svg"'
    assert_includes html, 'After the badge.'
    assert_equal 0, @engine.log.warning_count
  end

end
