$:.unshift( "../lib" )
require 'capcode'

module Capcode
  set :server, :webrick
  set :port, 3210

  class Index < Route '/'
    def get
      render "Hello World"
    end
  end  
end

Capcode.run( )