require 'erb'

module Capcode
  module Helpers
    @@__ERB_PATH__ = "."
    
    # Set the path to ERB files. If this path is not set, Capcode will search in the static path.
    def self.erb_path=( p )
      @@__ERB_PATH__ = p
    end
    
    def get_binding #:nodoc:
      binding
    end
    
    def render_erb( f, opts ) #:nodoc:
      if @@__ERB_PATH__.nil?
        @@__ERB_PATH__ = "." + (Capcode.static.nil? == false)?Capcode.static():''
      end
      
      f = f.to_s
      if f.include? '..'
        return [403, {}, '403 - Invalid path']
      end
      
      if /Windows/.match( ENV['OS'] )
        unless( /.:\\/.match( @@__ERB_PATH__[0] ) )
          @@__ERB_PATH__ = File.expand_path( File.join(".", @@__ERB_PATH__) )
        end
      else
        unless( @@__ERB_PATH__[0].chr == "/" )
          @@__ERB_PATH__ = File.expand_path( File.join(".", @@__ERB_PATH__) )
        end
      end

      layout = opts.delete(:layout)||:layout
      layout_file = File.join( @@__ERB_PATH__, layout.to_s+".rhtml" )

      f = f + ".rhtml" if File.extname( f ) != ".rhtml"
      file = File.join( @@__ERB_PATH__, f )
      
      if( File.exist?( layout_file ) )
        ERB.new(open(layout_file).read).result( get_binding { |*args| 
          @@__ARGS__ = args
          ERB.new(open(file).read).result(binding) 
        } )
      else
        ERB.new(open(file).read).result(binding)
      end
    end
  end
end