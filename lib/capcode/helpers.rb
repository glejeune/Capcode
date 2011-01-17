module Capcode
  # Helpers contains methods available in your controllers
  module Helpers
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
    # Or you can use a "HTTP code" renderer :
    #
    #   render 200 => "Ok", :server => "Capcode #{Capcode::CAPCOD_VERION}", ...
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
        possible_code_renderer = nil
        
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
          
          if key.class == Fixnum
            possible_code_renderer = key
          end
        end
        
        if render_type.nil? and possible_code_renderer.nil?
          raise Capcode::RenderError, "Renderer type not specified!", caller
        end
        
        unless self.respond_to?("render_#{render_type.to_s}")
          if possible_code_renderer.nil?
            raise Capcode::RenderError, "#{render_type} renderer not present ! please require 'capcode/render/#{render_type}'", caller
          else
            code = possible_code_renderer
            body = hash.delete(possible_code_renderer)
            header = {}
            hash.each do |k, v|
              k = k.to_s.split(/_/).map{|e| e.capitalize}.join("-")
              header[k] = v
            end
            
            [code, header, body]
          end
        else
          render_name = hash.delete(render_type)
          content_type = hash.delete(:content_type)
          unless content_type.nil?
            @response['Content-Type'] = content_type
          end
          
          begin
            self.send( "render_#{render_type.to_s}", render_name, hash )
          rescue => e
            raise Capcode::RenderError, "Error rendering `#{render_type.to_s}' : #{e.message}"#, caller
          end
        end
      else
        render( :text => hash )
      end
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
      result = {}

      a = a.delete_if{ |x| x.nil? }
      
      if klass.class == Class
        klass.__urls__[0].each do |cpath, data|
          args = a.clone
          
          n = Regexp.new( data[:regexp] ).number_of_captures
          equart = (a.size - n).abs
          
          rtable = data[:regexp].dup.gsub( /\\\(/, "" ).gsub( /\\\)/, "" ).split( /\([^\)]*\)/ )
          rtable.each do |r|
            if r == ""
              cpath = cpath + "/#{args.shift}"
            else
              cpath = cpath + "/#{r}"
            end
          end

          cpath = (cpath + "/" + args.join( "/" )) if args.size > 0
          cpath = cpath.gsub( /(\/){2,}/, "/" )
          result[equart] = cpath
        end

        path = result[result.keys.min]
      else
        path = klass
      end
      
      (ENV['RACK_BASE_URI']||'')+path
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
        :path => File.expand_path( File.join(Capcode::Configuration.get(:root), Capcode::Configuration.get(:static) ) )
      }
    end
    
    # Use the Rack logger
    #
    #   log.write( "This is a log !" )
    def log
      Capcode.logger || env['rack.errors']
    end
  end
end