$:.unshift( "../lib" )
require 'capcode'
require 'rubygems'
require 'graphviz'
require 'base64'

def hello( path )
  g = GraphViz::new( "G" ) { |g|
    g.hello << g.world
    g.bonjour - g.monde
    g.hola > g.mundo
    g.holla >> g.welt
  }
  
  r = nil
  if path.nil?
    r = g.output( :png => String )
  else
    r = g.output( :png => String, :path => "/#{path}" )
  end
  
  return r
end

module Capcode
  class Index < Route '/'
    def get
      render :markaby => :index
    end
  end
    
  class Image < Route '/image/(.*)'
    def get(path)
      r = hello( path )

      render :content_type => "image/png", :text => r
    end
  end
  
  class Inline < Route '/inline/(.*)'
    def get(path)
      @image = Base64.encode64(hello(path))

      render :markaby => :inline
    end
  end
end

module Capcode::Views
  def glop
    html do
      body do
        yield
      end
    end
  end
  
  def index
    h1 "Image :"
    img :src => URL(Capcode::Image)
  end
  
  def inline
    h1 "Inline image :"
    img :src => "data:image/png;base64,#{@image}"
  end
end

Capcode.run( )