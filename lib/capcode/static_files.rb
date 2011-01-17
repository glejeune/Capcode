module Capcode
  # Static file loader
  #
  # Use : 
  #   set :static, "path/to/static"
  class StaticFiles
    def initialize(app)
      @app = app
    end
    
    def call(env)
      static = File.expand_path( File.join(Capcode::Configuration.get(:root), Capcode::Configuration.get(:static) ) )
      file = File.join(static, env['REQUEST_PATH'].split("/") )
      file = File.join(file, "index.html" ) if File.directory?(file)
      if File.exist?(file)
        body = [::File.read(file)]
        header = {
          "Last-Modified" => ::File.mtime(file).httpdate,
          "Content-Type" => ::Rack::Mime.mime_type(::File.extname(file), 'text/plain'),
          "Content-Length" => body.first.size.to_s
        }
        return [200, header, body]
      else
        return @app.call(env)
      end
      
      return @app.call(env)
    end
  end
end