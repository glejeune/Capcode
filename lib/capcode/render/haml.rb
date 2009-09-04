require "haml"

module Capcode
  module Helpers
    @@__HAML_PATH__ = nil
    # Set the path to Haml files. If this path is not set, Capcode will search in the static path.
    def self.haml_path=( p )
      @@__HAML_PATH__ = p
    end
    
    def render_haml( f, opts ) #:nodoc:
      if @@__HAML_PATH__.nil?
        @@__HAML_PATH__ = "." + (Capcode.static.nil? == false)?Capcode.static():''
      end
      
      f = f.to_s
      if f.include? '..'
        return [403, {}, '403 - Invalid path']
      end
      
      if /Windows/.match( ENV['OS'] )
        unless( /.:\\/.match( @@__HAML_PATH__[0] ) )
          @@__HAML_PATH__ = File.expand_path( File.join(".", @@__HAML_PATH__) )
        end
      else
        unless( @@__HAML_PATH__[0].chr == "/" )
          @@__HAML_PATH__ = File.expand_path( File.join(".", @@__HAML_PATH__) )
        end
      end
       
      layout = opts.delete(:layout)||:layout
      layout_file = File.join( @@__HAML_PATH__, layout.to_s+".haml" )
      
      f = f + ".haml" if File.extname( f ) != ".haml"
      file = File.join( @@__HAML_PATH__, f )

      if( File.exist?( layout_file ) )
        Haml::Engine.new( open( layout_file ).read ).to_html(self) { |*args| 
          @@__ARGS__ = args
          Haml::Engine.new( open( file ).read ).render(self) 
        }
      else
        Haml::Engine.new( open( file ).read ).to_html( self )
      end
    end
  end
end