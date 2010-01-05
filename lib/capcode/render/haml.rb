begin
  require 'haml'
rescue LoadError => e
  raise MissingLibrary, "Haml could not be loaded (is it installed?): #{e.message}"
end

module Capcode
  module Helpers
    # Set the path to Haml files. If this path is not set, Capcode will search in the static path.
    # This method is deprecated and will be removed in version 1.0
    def self.haml_path=( p )
      warn "Capcode::Helpers.haml_path is deprecated and will be removed in version 1.0, please use `set :haml'"
      Capcode::Configuration.set :haml, p
    end
    
    def render_haml( f, opts = {} ) #:nodoc:
      if @haml_path.nil?
        @haml_path = Capcode::Configuration.get( :haml ) || Capcode.static()
      end
      
      f = f.to_s
      if f.include? '..'
        return [403, {}, '403 - Invalid path']
      end
      
      if /Windows/.match( ENV['OS'] )
        unless( /.:\\/.match( @haml_path[0] ) )
          @haml_path = File.expand_path( File.join(".", @haml_path) )
        end
      else
        unless( @haml_path[0].chr == "/" )
          @haml_path = File.expand_path( File.join(".", @haml_path) )
        end
      end
      
      # Update options
      opts = (Capcode.options[:haml] || {}).merge(opts)
      
      # Get Layout file
      layout = opts.delete(:layout)||:layout
      layout_file = File.join( @haml_path, layout.to_s+".haml" )
      
      # Get HAML File
      f = f + ".haml" if File.extname( f ) != ".haml"
      file = File.join( @haml_path, f )

      # Render
      if( File.exist?( file ) )
        if( File.exist?( layout_file ) )
          Haml::Engine.new( open( layout_file ).read, opts ).to_html(self) { |*args| 
            #@@__ARGS__ = args
            Capcode::Helpers.args = args
            Haml::Engine.new( open( file ).read ).render(self) 
          }
        else
          Haml::Engine.new( open( file ).read, opts ).to_html( self )
        end
      else
        raise Capcode::RenderError, "Error rendering `haml', #{file} does not exist !"
      end
    end
  end
end