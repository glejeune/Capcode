# Please read the README.rdoc file !

require 'rubygems'
require 'rack'
require 'json' ## DELETE THIS IN 1.0.0
require 'logger'
Logger.class_eval { alias :write :"<<" } unless Logger.instance_methods.include? "write"
require 'optparse'
require 'irb'
require 'mime/types'
require 'capcode/version'
require 'capcode/core_ext'
require 'capcode/helpers/auth'
require 'capcode/render/text'
require 'capcode/configuration'

module Capcode
  #@@__ROUTES = {}
  #@@__STATIC_DIR = nil
  #@@__APP = nil
  
  # @@__FILTERS = []
  # def self.before_filter( opts, &b )
  #   opts[:action] = b
  #   @@__FILTERS << opts
  # end
  
  
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
    #@@__ARGS__ = nil
    def self.args
      @args ||= nil
    end
    def self.args=(x)
      @args = x
    end
    
    # Render a view
    # 
    # render's parameter can be a Hash or a string. Passing a string is equivalent to do
    #   render( :text => string )
    # 
    # If you want to use a specific renderer, use one of this options :
    # 
    # * :markaby => :my_func : :my_func must be defined in Capcode::Views
    # * :erb => :my_erb_file : this suppose that's my_erb_file.rhtml exist in erb_path
    # * :haml => :my_haml_file : this suppose that's my_haml_file.haml exist in haml_path
    # * :sass => :my_sass_file : this suppose that's my_sass_file.sass exist in sass_path
    # * :text => "my text"
    # * :json => MyObject : this suppose that's MyObject respond to .to_json
    # * :static => "my_file.xxx" : this suppose that's my_file.xxx exist in the static directory
    # * :xml => :my_func : :my_func must be defined in Capcode::Views
    # * :webdav => /path/to/root
    #
    # If you want to use a specific layout, you can specify it with option 
    #   :layout
    #
    # If you want to change the Content-Type, you can specify it with option
    #   :content_type
    # Note that this will not work with the JSON renderer
    #
    # If you use the WebDav renderer, you can use the option 
    #   :resource_class (see http://github.com/georgi/rack_dav for more informations)
    def render( hash )
      if hash.class == Hash
        render_type = nil
        
        if render_type.nil?
          hash.keys.each do |key|
            begin
              gem "capcode-render-#{key.to_s}"
              require "capcode/render/#{key.to_s}"
            rescue Gem::LoadError
              nil
            rescue LoadError
              raise Capcode::RenderError, "Hum... The #{key} renderer is malformated! Please try to install a new version or use an other renderer!", caller
            end
       
            if self.respond_to?("render_#{key.to_s}")
              unless render_type.nil?
                raise Capcode::RenderError, "Can't use multiple renderer (`#{render_type}' and `#{key}') !", caller
              end
              render_type = key
            end
          end
          
          if render_type.nil?
            raise Capcode::RenderError, "Renderer type not specified!", caller
          end
        end
        unless self.respond_to?("render_#{render_type.to_s}")
          raise Capcode::RenderError, "#{render_type} renderer not present ! please require 'capcode/render/#{render_type}'", caller
        end

        render_name = hash.delete(render_type)
        content_type = hash.delete(:content_type)
        unless content_type.nil?
          @response['Content-Type'] = content_type
        end

        begin
          self.send( "render_#{render_type.to_s}", render_name, hash )
        rescue => e
          raise Capcode::RenderError, "Error rendering `#{render_type.to_s}' : #{e.message}", caller
        end
      else
        render( :text => hash )
      end
    end
    
    # Help you to return a JSON response
    #
    #   module Capcode
    #     class JsonResponse < Route '/json/([^\/]*)/(.*)'
    #       def get( arg1, arg2 )
    #         json( { :1 => arg1, :2 => arg2 })
    #       end
    #     end
    #   end
    #
    # <b>DEPRECATED</b>, please use <tt>render( :json => o )</tt>
    def json( d ) ## DELETE THIS IN 1.0.0
      warn( "json is deprecated and will be removed in version 1.0, please use `render( :json => ... )'" )
      @response['Content-Type'] = 'application/json'
      d.to_json
    end
    
    # Send a redirect response
    #
    #   module Capcode
    #     class Hello < Route '/hello/(.*)'
    #       def get( you )
    #         if you.nil?
    #           redirect( WhoAreYou )
    #         else
    #           ...
    #         end
    #       end
    #     end    
    #   end
    #
    # The first parameter can be a controller class name
    #
    #   redirect( MyController )
    #
    # it can be a string path
    #
    #   redirect( "/path/to/my/resource" )
    #
    # it can be an http status code (by default <tt>redirect</tt> use the http status code 302)
    #
    #   redirect( 304, MyController )
    # 
    # For more informations about HTTP status, see http://en.wikipedia.org/wiki/List_of_HTTP_status_codes#3xx_Redirection
    def redirect( klass, *a )
      httpCode = 302

      if( klass.class == Fixnum )
        httpCode = klass
        klass = a.shift
      end

      [httpCode, {'Location' => URL(klass, *a)}, '']
    end
    
    # Builds an URL route to a controller or a path
    #
    # if you declare the controller Hello :
    # 
    #   module Capcode
    #     class Hello < Route '/hello/(.*)'
    #       ...
    #     end
    #   end
    # 
    # then
    # 
    #   URL( Capcode::Hello, "you" ) # => /hello/you
    def URL( klass, *a )
      path = nil
      a = a.delete_if{ |x| x.nil? }
      
      if klass.class == Class
        Capcode.routes.each do |p, k|
          path = p if k.class == klass
        end
      else
        path = klass
      end
      
      (ENV['RACK_BASE_URI']||'')+path+((a.size>0)?("/"+a.join("/")):(""))
    end
    
    # Calling content_for stores a block of markup in an identifier.
    #
    #   module Capcode
    #     class ContentFor < Route '/'
    #       def get
    #         render( :markaby => :page, :layout => :layout )
    #       end
    #     end
    #   end
    #
    #   module Capcode::Views
    #     def layout
    #       html do
    #         head do
    #           yield :header
    #         end
    #         body do
    #           yield :content
    #         end
    #       end
    #     end
    #   
    #     def page
    #       content_for :header do
    #         title "This is the title!"
    #       end
    #   
    #       content_for :content do
    #         p "this is the content!"
    #       end
    #     end
    #   end
    def content_for( x )
      #if @@__ARGS__.map{|_| _.to_s }.include?(x.to_s)
      if Capcode::Helpers.args.map{|_| _.to_s }.include?(x.to_s)
        yield
      end
    end
    
    # Return information about the static directory
    # 
    # * <tt>static[:uri]</tt> give the static URI
    # * <tt>static[:path]</tt> give the path to the static directory on the server
    def static
      { 
        :uri => Capcode.static,
        :path => File.expand_path( File.join(".", Capcode.static ) )
      }
    end
    
    include Authorization
  end
  
  include Rack
  
  # HTTPError help you to create your own 404, 500 and/or 501 response
  # 
  # To create a custom 404 reponse, create a fonction HTTPError.r404 in
  # your application :
  #
  #   module Capcode
  #     class HTTPError
  #       def r404(f)
  #         "#{f} not found :("
  #       end
  #     end
  #   end
  #
  # Do the same (r500, r501, r403) to customize 500, 501, 403 errors
  class HTTPError
    def initialize(app) #:nodoc:
      @app = app
    end

    def call(env) #:nodoc:
      status, headers, body = @app.call(env)
      
      if self.methods.include? "r#{status}"
        body = self.send( "r#{status}", env['REQUEST_PATH'] )
        headers['Content-Length'] = body.length.to_s
      end
      
      [status, headers, body]
    end
  end
    
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
      Class.new {
        meta_def(:__urls__) {
          # < Route '/hello/world/([^\/]*)/id(\d*)', '/hello/(.*)', :agent => /Songbird (\d\.\d)[\d\/]*?/
          # # => [ {'/hello/world' => '([^\/]*)/id(\d*)', '/hello' => '(.*)'}, 
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
                hash_of_routes[current_route_path] = ''
              else
                _pre = m.pre_match
                _pre = "/" if _pre.size == 0
                raise Capcode::RouteError, "Route `#{_pre}' already defined with regexp `#{hash_of_routes[_pre]}' !", caller if hash_of_routes.keys.include?(_pre)
                hash_of_routes[_pre] = m.captures[0]
                max_captures_for_routes = Regexp.new(m.captures[0]).number_of_captures if max_captures_for_routes < Regexp.new(m.captures[0]).number_of_captures
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
          @env['rack.session']
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

          # __k = self.class.to_s.split( /::/ )[-1].downcase.to_sym
          # @@__FILTERS.each do |f|
          #   proc = f.delete(:action)
          #   __run = true
          #   if f[:only]
          #     __run = f[:only].include?(__k)
          #   end
          #   if f[:except]
          #     __run = !f[:except].include?(__k)
          #   end
          #   
          #   # proc.call(self) if __run
          #   puts "call #{proc} for #{__k}"
          # end

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

            finalPath = nil
            finalArgs = nil
            finalNArgs = nil
            
            aPath = @request.path.gsub( /^\//, "" ).split( "/" )
            self.class.__urls__[0].each do |p, r|
              xPath = p.gsub( /^\//, "" ).split( "/" )
              if (xPath - aPath).size == 0
                diffArgs = aPath - xPath
                diffNArgs = diffArgs.size
                if finalNArgs.nil? or finalNArgs > diffNArgs
                  finalPath = p
                  finalNArgs = diffNArgs
                  finalArgs = diffArgs
                end
              end
              
            end
        
            nargs = self.class.__urls__[1]
            regexp = Regexp.new( self.class.__urls__[0][finalPath] )
            args = regexp.match( Rack::Utils.unescape(@request.path).gsub( Regexp.new( "^#{finalPath}" ), "" ).gsub( /^\//, "" ) )
            if args.nil?
              raise Capcode::ParameterError, "Path info `#{@request.path_info}' does not match route regexp `#{regexp.source}'"
            else
              args = args.captures.map { |x| (x.size == 0)?nil:x }
            end
            
            while args.size < nargs
              args << nil
            end

            case @env["REQUEST_METHOD"]
              when "GET"                      
                get( *args )
              when "POST"
                _method = params.delete( "_method" ) { |_| "post" }
                send( _method.downcase.to_sym, *args )
              else
                _method = @env["REQUEST_METHOD"]
                send( _method.downcase.to_sym, *args )
            end
          }
          if r.respond_to?(:to_ary)
            @response.status = r.shift #r[0]
            #r[1].each do |k,v|
            r.shift.each do |k,v|
              @response[k] = v
            end
            @response.body = r.shift #r[2]
          else
            @response.write r
          end
                    
          @response.finish
        end
                
        include Capcode::Helpers
        include Capcode::Views
      }      
    end
  
    # This method help you to map and URL to a Rack or What you want Helper
    # 
    #   Capcode.map( "/file" ) do
    #     Rack::File.new( "." )
    #   end
    def map( route, &b )
      #@@__ROUTES[route] = yield
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
      
      Capcode.constants.each do |k|
        begin
          if eval "Capcode::#{k}.public_methods(true).include?( '__urls__' )"
            hash_of_routes, max_captures_for_routes, klass = eval "Capcode::#{k}.__urls__"
            hash_of_routes.keys.each do |current_route_path|
              #raise Capcode::RouteError, "Route `#{current_route_path}' already define !", caller if @@__ROUTES.keys.include?(current_route_path)
              raise Capcode::RouteError, "Route `#{current_route_path}' already define !", caller if Capcode.routes.keys.include?(current_route_path)
              #@@__ROUTES[current_route_path] = klass.new
              Capcode.routes[current_route_path] = klass.new
            end
          end
        rescue => e
          raise e.message
        end
      end
      
      # Set Static directory
      #@@__STATIC_DIR = (conf[:static][0].chr == "/")?conf[:static]:"/"+conf[:static] unless conf[:static].nil?
      Capcode.static = (Capcode::Configuration.get(:static)[0].chr == "/")?Capcode::Configuration.get(:static):"/"+Capcode::Configuration.get(:static) unless Capcode::Configuration.get(:static).nil?
      
      # Initialize Rack App
      puts "** Map routes." if Capcode::Configuration.get(:verbose)
      #app = Rack::URLMap.new(@@__ROUTES)
      app = Rack::URLMap.new(Capcode.routes)
      puts "** Initialize static directory (#{Capcode::Configuration.get(:static)})" if Capcode::Configuration.get(:verbose)
      app = Rack::Static.new( 
        app, 
        #:urls => [@@__STATIC_DIR], 
        :urls => [Capcode.static], 
        :root => File.expand_path(Capcode::Configuration.get(:root)) 
      ) unless Capcode::Configuration.get(:static).nil?
      puts "** Initialize session" if Capcode::Configuration.get(:verbose)
      app = Rack::Session::Cookie.new( app, Capcode::Configuration.get(:session) )
      app = Capcode::HTTPError.new(app)
      app = Rack::ContentLength.new(app)
      app = Rack::Lint.new(app)
      app = Rack::ShowExceptions.new(app)
      #app = Rack::Reloader.new(app) ## -- NE RELOAD QUE capcode.rb -- So !!!
      # app = Rack::CommonLogger.new( app, Logger.new(conf[:log]) )
      
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
        app = Rack::CommonLogger.new( app, Logger.new(Capcode::Configuration.get(:log)) )
        
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
        end
      end
    end

    def routes #:nodoc:
      #@@__ROUTES
      @routes ||= {}
    end
    
    def static #:nodoc:
      #@@__STATIC_DIR
      @static_dir ||= nil
    end
    def static=(x) #:nodoc:
      #@@__STATIC_DIR
      @static_dir = x
    end
    
  end
end
