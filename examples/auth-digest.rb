$:.unshift( "../lib" )
require 'capcode'
require 'rack'

module Capcode
  class Index < Route '/auth'    
    def get
      # Digest HTTP Authentication
      http_authentication( :type => :digest, :opaque => "Hello World!", :realm => "My Capcode test!!!" ) {
        {
          "greg" => "toto",
          "mu" => "maia"
        }
      }
      render "Success !"
    end
  end 
  
  class Aaa < Route '/noauth'
    def get
      render "You don't need any special authorization here !"
    end
  end
end

Capcode.run( )