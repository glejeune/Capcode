$:.unshift( "../lib" )
require 'capcode'

module Capcode
  class Index < Route '/'
    def get
      render "Hello World"
    end
  end  
end

Capcode.run( )