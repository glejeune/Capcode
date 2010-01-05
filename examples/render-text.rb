$:.unshift( "../lib" )
require 'capcode'

module Capcode
  set :server, :webrick
  set :port, 1111

  class Index < Route '/'
    def get
      render "Hello World"
    end
  end  
end

Capcode.run( :port => 2222 )