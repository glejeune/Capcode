$:.unshift( "../lib" )
require 'capcode'
require 'capcode/render/markaby'

module Capcode
  class Index < Route '/'
    def get
      render :markaby => :index
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
  end
end

Capcode.run( )