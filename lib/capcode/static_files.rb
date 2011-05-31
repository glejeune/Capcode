require 'capcode/helpers'

module Capcode
  # Static file loader
  #
  # You can add declare a filter (with before_filter) using :StaticFiles
  #
  # Use : 
  #   set :static, "path/to/static"
  class StaticFiles
    def initialize(app)
      @app = app
    end
    
    def session
      env["rack.session"]
    end
    
    def env
      @env
    end
    
    def log
      env["rack.errors"]
    end
    
    def request
      @request
    end
    
    def response
      @response
    end
    
    def call(env)
      @env = env
      @response = Rack::Response.new
      @request = Rack::Request.new(@env)
      
      static = ::File.expand_path( ::File.join(Capcode::Configuration.get(:root), Capcode::Configuration.get(:static) ) )
      file = ::File.join(static, request.path.gsub(/^[\/]?#{Capcode::Configuration.get(:static)}/, "").split("/") )
      file = ::File.join(file, "index.html" ) if ::File.directory?(file)
      
      if ::File.exist?(file)
        filter_output = Capcode::Filter.execute( self )        
        if filter_output.nil?
          body = [::File.read(file)]
          header = {
            "Last-Modified" => ::File.mtime(file).httpdate,
            "Content-Type" => ::Rack::Mime.mime_type(::File.extname(file), 'text/plain'),
            "Content-Length" => body.first.size.to_s,
            "Cache-Control" => "no-cache, must-revalidate" 
          }
          
          return [200, header, body]
        else
          return filter_output
        end
      else
        return @app.call(env)
      end
      
      return @app.call(env)
    end
  
    include Capcode::Helpers
  end
end