$:.unshift( "../lib" )
require 'capcode'
require 'capcode/render/markaby'
require 'capcode/render/binary'
require 'rubygems'
require 'graphviz'

module Capcode
  class Index < Route '/'
    def get
      render :markaby => :index
    end
  end
  
  class Image < Route '/image'
    def get
      render :binary => :image, :content_type => "image/png"
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
    h1 "Hello !"
    img :src => URL(Capcode::Image)
  end
  
  def image
    GraphViz::new( "G" ) { |g|
      g.hello << g.world
      g.bonjour - g.monde
      g.hola > g.mundo
      g.holla >> g.welt
    }.output( :png => String )
  end
end

Capcode.run( )