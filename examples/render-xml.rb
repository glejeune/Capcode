$:.unshift( "../lib" )
require 'capcode'
require 'capcode/render/xml'

module Capcode
  class Index < Route '/'
    def get
      render :xml => :index
    end
  end  
end

module Capcode::Views
  def index
    xml? :version => '1.0'
    html do
      body do
        h1 "Hello XML !"
      end
    end
  end
end

Capcode.run( )