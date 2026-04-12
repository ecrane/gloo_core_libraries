# 
# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2026 Eric Crane.  All rights reserved.
#
# A shell context.
# Data associated with the shell session.
#
class ShellContext

  attr_accessor :done
  attr_reader :projects, :tasks
 
  def initialize
    @projects = [ "alpha", "beta", "gamma" ]
    @tasks = [ "task1", "task2" ]
  end

end