# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# Root Rakefile - runs every gem's own Ruby test suite, each in its
# own process via that gem's own Rakefile (`rake test`, not `bundle
# exec rake test` - under bundle exec, a gem's own Gemfile.lock
# doesn't include dev/gloo's runtime dependencies like activesupport,
# and test_helper.rb needs those to load gloo core's test scaffolding).
#
# Deliberately not aggregated in-process (one combined Rake::TestTask
# requiring every gem into the same Ruby process): no current
# class-name or require-path collision across gems, but nothing
# structurally prevents one either, and per-process isolation matches
# "each gem is independent" from the core-libraries CLAUDE.md. See
# the 🗣️ fix core lib test infrastructure vault story for the full
# design notes.
#

GEM_DIRS = Dir.glob( File.join( __dir__, 'gloo-*' ) ).select { |d| File.directory?( d ) }.sort

#
# Run each gem's own `rake test`, continuing past failures rather
# than stopping at the first one, then report a per-gem summary.
#
desc "Run every gem's own Ruby test suite"
task :test do
  results = []

  GEM_DIRS.each do |dir|
    name = File.basename( dir )
    rakefile = File.join( dir, 'Rakefile' )

    unless File.exist?( rakefile )
      results << { name: name, status: :skipped }
      next
    end

    puts
    puts "=== #{name} ==="
    success = Dir.chdir( dir ) { system( 'rake', 'test' ) }
    results << { name: name, status: success ? :passed : :failed }
  end

  puts
  puts '=== Summary ==='
  results.each do |r|
    label = case r[ :status ]
            when :passed  then 'PASS'
            when :failed  then 'FAIL'
            when :skipped then 'SKIP (no Rakefile yet)'
            end
    puts "  #{label.ljust( 22 )} #{r[ :name ]}"
  end

  failed = results.select { |r| r[ :status ] == :failed }
  if failed.any?
    puts
    puts "#{failed.count} gem(s) failed: #{failed.map { |r| r[ :name ] }.join( ', ' )}"
    exit 1
  end
end

task :default => :test
