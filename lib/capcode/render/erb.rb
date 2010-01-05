require 'erb'

module Capcode
  module Helpers
    # Set the path to ERB files. If this path is not set, Capcode will search in the static path.
    # This method is deprecated and will be removed in version 1.0
    def self.erb_path=( p )
      warn "Capcode::Helpers.erb_path is deprecated and will be removed in version 1.0, please use `set :erb'"
      Capcode::Configuration.set :erb, p
    end
    
    def get_binding #:nodoc:
      binding
    end
    
    def render_erb( f, opts ) #:nodoc:
      if @erb_path.nil?
        @erb_path = Capcode::Configuration.get( :erb ) || Capcode.static()
      end
      
      f = f.to_s
      if f.include? '..'
        return [403, {}, '403 - Invalid path']
      end
      
      if /Windows/.match( ENV['OS'] )
        unless( /.:\\/.match( @erb_path[0] ) )
          @erb_path = File.expand_path( File.join(".", @erb_path) )
        end
      else
        unless( @erb_path[0].chr == "/" )
          @erb_path = File.expand_path( File.join(".", @erb_path) )
        end
      end

      # Get Layout
      layout = opts.delete(:layout)||:layout
      layout_file = File.join( @erb_path, layout.to_s+".rhtml" )

      # Get file
      f = f + ".rhtml" if File.extname( f ) != ".rhtml"
      file = File.join( @erb_path, f )
      
      if( File.exist?( file ) )
        if( File.exist?( layout_file ) )
          ERB.new(open(layout_file).read).result( get_binding { |*args| 
            #@@__ARGS__ = args
            Capcode::Helpers.args = args
            ERB.new(open(file).read).result(binding) 
          } )
        else
          ERB.new(open(file).read).result(binding)
        end
      else
        raise Capcode::RenderError, "Error rendering `erb', #{file} does not exist !"
      end
    end
  end
end