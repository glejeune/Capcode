# Please read the README.rdoc file !

require 'rubygems'
require 'rack'
require 'rack/mime'
require 'logger'
Logger.class_eval { alias :write :<< } unless Logger.instance_methods.include? "write"
require 'optparse'
require 'irb'
require 'capcode/version'
require 'capcode/core_ext'
require 'capcode/helpers'
require 'capcode/helpers/auth'
require 'capcode/render/text'
require 'capcode/http_error'
require 'capcode/static_files'
require 'capcode/configuration'
require 'capcode/filters'
require 'capcode/ext/rack/urlmap'

module Capcode
  class ParameterError < ArgumentError #:nodoc: all
  end
  
  class RouteError < ArgumentError #:nodoc: all
  end
  
  class RenderError < ArgumentError #:nodoc: all
  end
  
  class MissingLibrary < Exception #:nodoc: all
  end
  
  # Views is an empty module in which you can store your markaby or xml views.
  module Views; end
  
  # Helpers contains methods available in your controllers
  module Helpers    
    include Authorization
  end
  
  include Rack
      
  class << self
    attr :__auth__, true #:nodoc:
    
    # Add routes to a controller class
    # 
    #   module Capcode
    #     class Hello < Route '/hello/(.*)', '/hello/([^#]*)#(.*)'
    #       def get( arg1, arg2 )
    #         ...
    #       end
    #     end
    #   end
    #
    # In the <tt>get</tt> method, you will receive the maximum of parameters declared
    # by the routes. In this example, you will receive 2 parameters. So if you
    # go to <tt>/hello/world#friend</tt> then <tt>arg1</tt> will be set to <tt>world</tt> and <tt>arg2</tt>
    # will be set to <tt>friend</tt>. Now if you go to <tt>/hello/you</tt>, then <tt>arg1</tt> will
    # be set to <tt>you</tt> and <tt>arg2</tt> will be set to <tt>nil</tt>
    # 
    # If the regexp in the route does not match, all arguments will be <tt>nil</tt>
    def Route *routes_paths
      create_path = routes_paths[0].nil?
      Class.new {
        meta_def(:__urls__) {
          routes_paths = ['/'+self.to_s.gsub( /^Capcode::/, "" ).underscore] if create_path == true
          # < Route '/hello/world/([^\/]*)/id(\d*)', '/hello/(.*)', :agent => /Songbird (\d\.\d)[\d\/]*?/
          # # => [ {
          #          '/hello/world' => {
          #            :regexp => '([^\/]*)/id(\d*)',
          #            :route => '/hello/world/([^\/]*)/id(\d*)',
          #            :nargs => 2
          #          },
          #          '/hello/world' => {
          #            :regexp => '(.*)',
          #            :route => '/hello/(.*)',
          #            :nargs => 1
          #          }
          #        },
          #        2, 
          #        <Capcode::Klass>, 
          #        {:agent => /Songbird (\d\.\d)[\d\/]*?/} ]
          hash_of_routes = {}
          max_captures_for_routes = 0
          routes_paths.each do |current_route_path|
            if current_route_path.class == String
              m = /\/([^\/]*\(.*)/.match( current_route_path )
              if m.nil?
                raise Capcode::RouteError, "Route `#{current_route_path}' already defined with regexp `#{hash_of_routes[current_route_path]}' !", caller if hash_of_routes.keys.include?(current_route_path)
                hash_of_routes[current_route_path] = {
                  :regexp => '',
                  :route => current_route_path,
                  :nargs => 0
                }
              else
                _pre = m.pre_match
                _pre = "/" if _pre.size == 0
                raise Capcode::RouteError, "Route `#{_pre}' already defined with regexp `#{hash_of_routes[_pre]}' !", caller if hash_of_routes.keys.include?(_pre)
                captures_for_routes = Regexp.new(m.captures[0]).number_of_captures
                
                hash_of_routes[_pre] = {
                  :regexp => m.captures[0],
                  :route => current_route_path,
                  :nargs => captures_for_routes
                }
                max_captures_for_routes = captures_for_routes if max_captures_for_routes < captures_for_routes
              end
            else
              raise Capcode::ParameterError, "Bad route declaration !", caller
            end
          end
          [hash_of_routes, max_captures_for_routes, self]
        }
                
        # Hash containing all the request parameters (GET or POST)
        def params
          @request.params
        end
        
        # Hash containing all the environment variables
        def env
          @env
        end
        
        # Session hash
        def session
          env['rack.session']
        end
        
        # Return the Rack::Request object
        def request
          @request
        end
        
        # Return the Rack::Response object
        def response
          @response
        end
        
        def call( e ) #:nodoc:
          @env = e
          @response = Rack::Response.new
          @request = Rack::Request.new(@env)

          # Check authz
          authz_options = nil
          if Capcode.__auth__ and Capcode.__auth__.size > 0
            authz_options = Capcode.__auth__[@request.path]||nil
            if authz_options.nil?
              route = nil
              
              Capcode.__auth__.each do |r, o|
                regexp = "^#{r.gsub(/\/$/, "")}([/]{1}.*)?$"
                if Regexp.new(regexp).match( @request.path )
                  if route.nil? or r.size > route.size
                    route = r
                    authz_options = o
                  end
                end  
              end
            end
          end

          r = catch(:halt) { 
            unless authz_options.nil?
              http_authentication( :type => authz_options[:type], :realm => authz_options[:realm], :opaque => authz_options[:realm] ) { 
                authz_options[:autz]
              }
            end

            max_match_size = self.class.__urls__[1]
            match_distance = self.class.__urls__[1]

            result_route = nil
            result_nargs = nil
            result_args = []

            self.class.__urls__[0].each do |route, data|
              regexp = Regexp.new("^"+data[:route]+"$")

              matching = regexp.match(@request.path)
              next if matching.nil?

              result_args = matching.to_a
              result_args.shift
              match_size = matching.size - 1

              if match_size == max_match_size
                # OK Terminé
                result_route = data[:route]
                result_nargs = data[:nargs]

                break
              elsif max_match_size > match_size and match_distance > max_match_size - match_size
                match_distance = max_match_size - match_size

                result_route = data[:route]
                result_nargs = data[:nargs]
              end
            end
            
            return [404, {'Content-Type' => 'text/plain'}, "Not Found: #{@request.path}"] if result_route.nil?

            result_args = result_args + Array.new(max_match_size - result_nargs)

            filter_output = Capcode::Filter.execute( self )

            if( filter_output.nil? )
              # case @env["REQUEST_METHOD"]
              #   when "GET"                      
              #     get( *args )
              #   when "POST"
              #     _method = params.delete( "_method" ) { |_| "post" }
              #     send( _method.downcase.to_sym, *args )
              #   else
              #     _method = @env["REQUEST_METHOD"]
              #     send( _method.downcase.to_sym, *args )
              # end
              begin
                _method = params.delete( "_method" ) { |_| @env["REQUEST_METHOD"] }
                if self.class.method_defined?( _method.downcase.to_sym )
                  # send( _method.downcase.to_sym, *args )
                  send( _method.downcase.to_sym, *result_args )
                else
                  # any( *args )
                  any( *result_args )
                end
              rescue => e
                raise e.class, e.to_s
              end
            else
              filter_output
            end
          }
          
          if r.respond_to?(:to_ary)
            @response.status = r.shift #r[0]
            #r[1].each do |k,v|
            r.shift.each do |k,v|
              @response[k] = v
            end
            @response.write r.shift #r[2]
          else
            @response.write r
          end
          
          @response.finish
        end
                
        include Capcode::Helpers
        include Capcode::Views        
      }      
    end
    Capcode::Route = Capcode::Route(nil)
    
    # This method help you to map and URL to a Rack or What you want Helper
    # 
    #   Capcode.map( "/file" ) do
    #     Rack::File.new( "." )
    #   end
    def map( route, &b )
      Capcode.routes[route] = yield
    end
    
    # This method allow you to use a Rack middleware
    #
    # Example :
    #
    #   module Capcode
    #     ...
    #     use Rack::Codehighlighter, :coderay, :element => "pre", 
    #       :pattern => /\A:::(\w+)\s*\n/, :logging => false
    #     ...
    #   end
    def use(middleware, *args, &block)
      middlewares << [middleware, args, block]
    end
    def middlewares #:nodoc:
      @middlewares ||= []
    end

    # Allow you to add and HTTP Authentication (Basic or Digest) to controllers for or specific route
    # 
    # Options :
    # * <tt>:type</tt> : Authentication type (<tt>:basic</tt> or <tt>:digest</tt>) - default : <tt>:basic</tt>
    # * <tt>:realm</tt> : realm ;) - default : "Capcode.app"
    # * <tt>:opaque</tt> : Your secret passphrase. You MUST set it if you use Digest Auth - default : "opaque"
    # * <tt>:routes</tt> : Routes - default : "/"
    #
    # The block must return a Hash of username => password like that :
    #   {
    #     "user1" => "pass1",
    #     "user2" => "pass2",
    #     # ...
    #   }
    def http_authentication( opts = {}, &b )
      options = {
        :type => :basic,
        :realm => "Capcode.app",
        :opaque => "opaque",
        :routes => "/"
      }.merge( opts )
      
      options[:autz] = b.call()
      
      @__auth__ ||= {}
      
      if options[:routes].class == Array
        options[:routes].each do |r|
          @__auth__[r] = options
        end
      else
        @__auth__[options[:routes]] = options
      end      
    end
  
    # Return the Rack App.
    # 
    # Options : see Capcode::Configuration.set
    #
    # Options set here replace the ones set globally
    def application( args = {} )
      Capcode::Configuration.configuration(args)
      Capcode::Configuration.print_debug if Capcode::Configuration.get(:verbose)
      
      Capcode.constants.clone.delete_if {|k| 
        not( Capcode.const_get(k).to_s =~ /Capcode/ ) or [
          "Filter", 
          "Helpers", 
          "RouteError", 
          "Views", 
          "ParameterError", 
          "HTTPError", 
          "StaticFiles",
          "Configuration", 
          "MissingLibrary", 
          "Route", 
          "RenderError"
        ].include?(k)
      }.each do |k|
        begin
          if eval "Capcode::#{k}.public_methods(true).include?( '__urls__' )"
            hash_of_routes, max_captures_for_routes, klass = eval "Capcode::#{k}.__urls__"            
            hash_of_routes.keys.each do |current_route_path|
              raise Capcode::RouteError, "Route `#{current_route_path}' already define !", caller if Capcode.routes.keys.include?(current_route_path)
              Capcode.routes[current_route_path] = klass
            end
          end
        rescue => e
          raise e.message
        end
      end
      
      # Set Static directory
      Capcode.static = (Capcode::Configuration.get(:static)[0].chr == "/")?Capcode::Configuration.get(:static):"/"+Capcode::Configuration.get(:static) unless Capcode::Configuration.get(:static).nil?
      
      # Initialize Rack App
      puts "** Map routes." if Capcode::Configuration.get(:verbose)
#      app = Rack::URLMap.new(Capcode.routes)
      app = Capcode::Ext::Rack::URLMap.new(Capcode.routes)
      puts "** Initialize static directory (#{Capcode.static}) in #{File.expand_path(Capcode::Configuration.get(:root))}" if Capcode::Configuration.get(:verbose)
      
      #app = Rack::Static.new( 
      #  app, 
      #  #:urls => [@@__STATIC_DIR], 
      #  :urls => [Capcode.static], 
      #  :root => File.expand_path(Capcode::Configuration.get(:root)) 
      #) unless Capcode::Configuration.get(:static).nil?
      
      puts "** Initialize session" if Capcode::Configuration.get(:verbose)
      app = Capcode::StaticFiles.new(app)
      app = Capcode::HTTPError.new(app)
      app = Rack::Session::Cookie.new( app, Capcode::Configuration.get(:session) )
      app = Rack::ContentLength.new(app)
      app = Rack::Lint.new(app)
      app = Rack::ShowExceptions.new(app)
      #app = Rack::Reloader.new(app) ## -- NE RELOAD QUE capcode.rb -- So !!!
      app = Rack::CommonLogger.new( app, @cclogger = Logger.new(Capcode::Configuration.get(:log)) )
      
      middlewares.each do |mw|
        middleware, args, block = mw
        puts "** Load middleware #{middleware}" if Capcode::Configuration.get(:verbose)
        if block
          app = middleware.new( app, *args, &block )
        else
          app = middleware.new( app, *args )
        end
      end
      
      # Start database
      if self.methods.include? "db_connect"
        db_connect( Capcode::Configuration.get(:db_config), Capcode::Configuration.get(:log) )
      end
      
      if block_given?
        puts "** Execute block" if Capcode::Configuration.get(:verbose)
        yield( self )
      end
      
      return app
    end
    
    # Start your application.
    # 
    # Options : see Capcode::Configuration.set
    #
    # Options set here replace the ones set globally
    def run( args = {} )
      Capcode::Configuration.configuration(args)
      
      # Parse options
      opts = OptionParser.new do |opts|
        opts.banner = "Usage: #{File.basename($0)} [options]"
        opts.separator ""
        opts.separator "Specific options:"

        opts.on( "-C", "--console", "Run in console mode with IRB (default: false)" ) { 
          Capcode::Configuration.set :console, true
        }
        opts.on( "-h", "--host HOSTNAME", "Host for web server to bind to (default: #{Capcode::Configuration.get(:host)})" ) { |h|
          Capcode::Configuration.set :host, h
        }
        opts.on( "-p", "--port NUM", "Port for web server (default: #{Capcode::Configuration.get(:port)})" ) { |p|
          Capcode::Configuration.set :port, p
        }
        opts.on( "-d", "--daemonize [true|false]", "Daemonize (default: #{Capcode::Configuration.get(:daemonize)})" ) { |d|
          Capcode::Configuration.set :daemonize, d
        }
        opts.on( "-r", "--root PATH", "Working directory (default: #{Capcode::Configuration.get(:root)})" ) { |w|
          Capcode::Configuration.set :root, w
        }
        opts.on( "-s", "--static PATH", "Static directory -- relative to the root directory (default: #{Capcode::Configuration.get(:static)})" ) { |r|
          Capcode::Configuration.set :static, r
        }
        opts.on( "-S", "--server SERVER", "Server to use (default: #{Capcode::Configuration.get(:server)})" ) { |r|
          Capcode::Configuration.set :server, r
        }

        opts.separator ""
        opts.separator "Common options:"

        opts.on("-?", "--help", "Show this message") do
          puts opts
          exit
        end  
        opts.on("-v", "--version", "Show versions") do
          puts "Capcode version #{Capcode::CAPCOD_VERION} (ruby v#{RUBY_VERSION})"
          exit
        end  
        opts.on_tail( "-V", "--verbose", "Run in verbose mode" ) do
          Capcode::Configuration.set :verbose, true
        end
      end
      
      begin
        opts.parse! ARGV
      rescue OptionParser::ParseError => ex
        puts "!! #{ex.message}"
        puts "** use `#{File.basename($0)} --help` for more details..."
        exit 1
      end
      
      # Run in the Working directory
      puts "** Go on root directory (#{File.expand_path(Capcode::Configuration.get(:root))})" if Capcode::Configuration.get(:verbose)
      Dir.chdir( Capcode::Configuration.get(:root) ) do
        
        # Check that mongrel exists 
        if Capcode::Configuration.get(:server).nil? || Capcode::Configuration.get(:server) == "mongrel"
          begin
            require 'mongrel'
            Capcode::Configuration.set :server, :mongrel
          rescue LoadError 
            puts "!! could not load mongrel. Falling back to webrick."
            Capcode::Configuration.set :server, :webrick
          end
        end
        
        # From rackup !!!
        if Capcode::Configuration.get(:daemonize)
          if /java/.match(RUBY_PLATFORM).nil?
            if RUBY_VERSION < "1.9"
              exit if fork
              Process.setsid
              exit if fork
              # Dir.chdir "/"
              File.umask 0000
              STDIN.reopen "/dev/null"
              STDOUT.reopen "/dev/null", "a"
              STDERR.reopen "/dev/null", "a"
            else
              Process.daemon
            end
          else
            puts "!! daemonize option unavailable on #{RUBY_PLATFORM} platform."
          end
        
          File.open(Capcode::Configuration.get(:pid), 'w'){ |f| f.write("#{Process.pid}") }
          at_exit { File.delete(Capcode::Configuration.get(:pid)) if File.exist?(Capcode::Configuration.get(:pid)) }
        end
        
        app = nil
        if block_given?
          app = application(Capcode::Configuration.get) { yield( self ) }
        else
          app = application(Capcode::Configuration.get)
        end
        
        if Capcode::Configuration.get(:console)
          puts "Run console..."
          IRB.start
          exit
        end
        
        # Start server
        case Capcode::Configuration.get(:server).to_s
        when "mongrel"
          puts "** Starting Mongrel on #{Capcode::Configuration.get(:host)}:#{Capcode::Configuration.get(:port)}"
          Rack::Handler::Mongrel.run( app, {:Port => Capcode::Configuration.get(:port), :Host => Capcode::Configuration.get(:host)} ) { |server|
            trap "SIGINT", proc { server.stop }
          }
        when "webrick"
          puts "** Starting WEBrick on #{Capcode::Configuration.get(:host)}:#{Capcode::Configuration.get(:port)}"
          Rack::Handler::WEBrick.run( app, {:Port => Capcode::Configuration.get(:port), :BindAddress => Capcode::Configuration.get(:host)} ) { |server|
            trap "SIGINT", proc { server.shutdown }
          }
        when "thin"
          puts "** Starting Thin on #{Capcode::Configuration.get(:host)}:#{Capcode::Configuration.get(:port)}"
          Rack::Handler::Thin.run( app, {:Port => Capcode::Configuration.get(:port), :Host => Capcode::Configuration.get(:host)} ) { |server|
            trap "SIGINT", proc { server.stop }
          }
        when "unicorn"
          require 'unicorn/launcher'
          puts "** Starting Unicorn on #{Capcode::Configuration.get(:host)}:#{Capcode::Configuration.get(:port)}"
          Unicorn.run( app, {:listeners => ["#{Capcode::Configuration.get(:host)}:#{Capcode::Configuration.get(:port)}"]} )
        when "rainbows"
          require 'unicorn/launcher'
          require 'rainbows'
          puts "** Starting Rainbow on #{Capcode::Configuration.get(:host)}:#{Capcode::Configuration.get(:port)}"
          Rainbows.run( app, {:listeners => ["#{Capcode::Configuration.get(:host)}:#{Capcode::Configuration.get(:port)}"]} )
        when "control_tower"
          require 'control_tower'
          puts "** Starting ControlTower on #{Capcode::Configuration.get(:host)}:#{Capcode::Configuration.get(:port)}"
          ControlTower::Server.new( app, {:host => Capcode::Configuration.get(:host), :port => Capcode::Configuration.get(:port)} ).start
        end
      end
    end

    def routes #:nodoc:
      @routes ||= {}
    end
    
    def logger
      @cclogger
    end
    
    def static #:nodoc:
      @static_dir ||= nil
    end
    def static=(x) #:nodoc:
      @static_dir = x
    end
    
  end
end
