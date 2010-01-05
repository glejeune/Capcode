begin
  require 'sass'
rescue LoadError => e
  raise MissingLibrary, "Sass could not be loaded (is it installed?): #{e.message}"
end

module Capcode
  module Helpers
    # Set the path to Sass files. If this path is not set, Capcode will search in the static path.
    # This method is deprecated and will be removed in version 1.0
    def self.sass_path=( p )
      warn "Capcode::Helpers.sass_path is deprecated and will be removed in version 1.0, please use `set :sass'"
      Capcode::Configuration.set :sass, p
    end
    
    def render_sass( f, _ ) #:nodoc:
      if @sass_path.nil?
        @sass_path = Capcode::Configuration.get( :sass ) || Capcode.static() 
      end
      
      f = f.to_s
      if f.include? '..'
        return [403, {}, '403 - Invalid path']
      end
      
      if /Windows/.match( ENV['OS'] )
        unless( /.:\\/.match( @sass_path[0] ) )
          @sass_path = File.expand_path( File.join(".", @sass_path) )
        end
      else
        unless( @sass_path[0].chr == "/" )
          @sass_path = File.expand_path( File.join(".", @sass_path) )
        end
      end
      
      # Get File
      f = f + ".sass" if File.extname( f ) != ".sass"
      file = File.join( @sass_path, f )

      # Render
      if( File.exist?( file ) )
        Sass::Engine.new( open( file ).read ).to_css
      else
        raise Capcode::RenderError, "Error rendering `sass', #{file} does not exist !"
      end
    end
  end
end