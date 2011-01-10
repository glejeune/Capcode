$:.unshift( "../lib" )
require 'capcode'
require 'rubygems'

module Capcode
  set :static, "static"
  
  class Index < Route '/'
    def get
      render :markaby => :index
    end
  end
end

module Capcode::Views
  def index
    html do
      body do
        h1 "Hello World!"
        a "Show me static", :href => "/static-index.html"
      end
    end
  end
end

Capcode.run( )