$:.unshift( "../lib" )
require 'capcode'

module Capcode

  http_authentication( :type => :basic, :realm => "Private part", :routes => "/noauth/private" ) { 
    {
      "greg" => "toto",
      "mu" => "maia"
    }
  }

  class Index < Route '/admin'    
    def get
      # Basic HTTP Authentication
      http_authentication( :type => :basic, :realm => "Admin part" ) { 
        {
          "greg" => "toto",
          "mu" => "maia"
        }
      }
      render "Success !"
    end
  end 
  
  class Noauth < Route '/noauth'
    def get
      render "You don't need any special authorization here !"
    end
  end
  
  class Private < Route '/noauth/private'
    def get
      render "Welcome in the private part !"
    end
  end

  class Private2 < Route '/noauth/private/again'
    def get
      render "Welcome in the private/again part !"
    end
  end
  
end

Capcode.run( )