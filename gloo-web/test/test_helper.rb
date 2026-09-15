# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# Loads the shared gloo core test scaffolding (Minitest, BaseTest,
# BaseEngineTest) from the sibling dev/gloo checkout, then requires
# this gem's own entry point directly so its classes are loaded
# from the local checkout, not from whatever version is gem
# installed.
#

#
# Path to the sibling gloo core interpreter checkout, per the fixed
# directory layout documented in gloo_meta/CLAUDE.md.
#
GLOO_CORE_PATH = File.expand_path( File.join( '..', '..', '..', 'gloo' ), __dir__ )

require File.join( GLOO_CORE_PATH, 'test', 'test_helper' )

#
# Requiring the gem's own entry point (from the local checkout, via
# `lib` on the test load path) is enough on its own - every object
# type self-registers into Gloo::Core::Dictionary at require time.
# Deliberately NOT going through Gloo::Plugin::LibManager#load_lib:
# that resolves the library purely through RubyGems (`gem name;
# require name`) and would silently test whatever version happens to
# be gem installed instead of the code in this working tree.
#
require 'gloo-web'
