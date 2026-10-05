# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2024 Eric Crane.  All rights reserved.
# 
# Starting work on web server inside gloo.
# 
#  UNDER CONSTRUCTION!
# 
# Simple tests:
#   > curl http://localhost:8087/test/
#   > curl http://localhost:8087/web/
#   > curl http://localhost:8087/test/1
#   > curl http://localhost:8087/test?param=123
# 
# Run in loop:
#  for i in {1..99}; do curl http://localhost:8087/; done
# 
# Links:
#   https://github.com/rack/rack
#   https://github.com/rack/rack/blob/main/lib/rack/builder.rb
#   https://thoughtbot.com/blog/ruby-rack-tutorial
#   https://www.rubydoc.info/gems/rack/1.5.5/Rack/Runtime
# 

require 'rack'

module WebSvr
  class Server

    # EventMachine (under Thin) raises a RuntimeError starting with this
    # when it can't listen: the port is in use or needs root.
    NO_ACCEPTOR = 'no acceptor'.freeze

    # ---------------------------------------------------------------------
    #    Initialization
    # ---------------------------------------------------------------------

    #
    # Set up the web server.
    #
    def initialize( engine, handler, config = nil, ssl_config = nil )
      @config = config ? config : WebSvr::Config.new
      @ssl_config = ssl_config
      @engine = engine
      @log = @engine.log
      @handler = handler

      @log.debug 'Gloo web server intialized…'
    end


    # ---------------------------------------------------------------------
    #    Start and Stop the server.
    # ---------------------------------------------------------------------

    # 
    # Start the web server.
    # 
    def start
      @server_thread = Thread.new { run_server }
      @log.debug 'Web server has started.'
    end

    # 
    # Run the web server. This doesn't return while the server is
    # running, so it runs in its own thread. If the server fails, it is
    # reported here and the running app is stopped.
    # 
    def run_server
      opts = {
        :Port => @config.port,
        :Host => @config.host
      }
      Rack::Handler::Thin.run( self, **opts ) do |server|
        if @ssl_config
          server.ssl = true
          server.ssl_options = @ssl_config
        end
      end
    rescue => e
      if e.message.start_with?( NO_ACCEPTOR )
        @engine.err "Could not start the web server on #{@config.host}:#{@config.port}: " \
          'the port is in use or needs root privileges.'
      else
        @engine.handle_exception e
      end
      @engine.stop_running_app
    end

    # 
    # Stop the web server
    # 
    def stop
      @log.debug 'Stopping the web server…'

      # When the server thread itself failed, it is ending already.
      @server_thread.kill unless Thread.current == @server_thread

      @log.debug 'The web server has been stopped.'
    end


    # ---------------------------------------------------------------------
    #    Handle events
    # ---------------------------------------------------------------------

    # 
    # Handle a request for a resource.
    # 
    def call( env )
      request = WebSvr::Request.new( @engine, @handler, env )
      request.log

      response = request.process

      # A page that failed to render gives no response.
      response ||= @handler.server_error_result
      response.log

      return response.result
    rescue => e
      # A bug in gloo-web's own code. Errors in gloo statements are
      # handled where they happen, so this is the unexpected case:
      # report it and send the error page.
      @engine.handle_exception e
      return error_result
    end

    # 
    # The result for a request that failed: the app's error page, or a
    # plain 500 if that fails too.
    # 
    def error_result
      return @handler.server_error_result.result
    rescue => e
      @engine.handle_exception e
      return [ WebSvr::ResponseCode::SERVER_ERR,
        { WebSvr::Response::CONTENT_TYPE => WebSvr::Response::TEXT_TYPE },
        WebSvr::Handler::SERVER_ERR_MSG ]
    end

  
  end
end
