require "sass"

module Capcode
  module Helpers
    @@__SASS_PATH__ = "."
    
    # Set the path to Sass files. If this path is not set, Capcode will search in the static path.
    def self.sass_path=( p ) #:nodoc:
      @@__SASS_PATH__ = p
    end
    
    def render_sass( f, _ ) #:nodoc:
      if @@__SASS_PATH__.nil?
        @@__SASS_PATH__ = "." + (Capcode.static.nil? == false)?Capcode.static():''
      end
      
      f = f.to_s
      if f.include? '..'
        return [403, {}, '403 - Invalid path']
      end
      
      if /Windows/.match( ENV['OS'] )
        unless( /.:\\/.match( @@__SASS_PATH__[0] ) )
          @@__SASS_PATH__ = File.expand_path( File.join(".", @@__SASS_PATH__) )
        end
      else
        unless( @@__SASS_PATH__[0].chr == "/" )
          @@__SASS_PATH__ = File.expand_path( File.join(".", @@__SASS_PATH__) )
        end
      end
       
      f = f + ".sass" if File.extname( f ) != ".sass"
      file = File.join( @@__SASS_PATH__, f )

      Sass::Engine.new( open( file ).read ).to_css
    end
  end
end