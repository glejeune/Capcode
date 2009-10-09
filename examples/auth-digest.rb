$:.unshift( "../lib" )
require 'capcode'
require 'digest/md5'

module Capcode
  OPAQUE = Digest::MD5.hexdigest( Time.now.to_s )
  http_authentication( :type => :digest, :opaque => OPAQUE, :realm => "Private part", :routes => "/noauth/private" ) { 
    {
      "greg" => "toto",
      "mu" => "maia"
    }
  }

  class Index < Route '/admin'    
    def get
      # Basic HTTP Authentication
      http_authentication( :type => :digest, :opaque => OPAQUE, :realm => "Admin part" ) { 
        {
          "greg" => "toto",
          "mu" => "maia"
        }
      }
      render "Welcome in admin part #{request.env['REMOTE_USER']}"
    end
  end 
  
  class Noauth < Route '/noauth'
    def get
      render "You don't need any special authorization here !"
    end
  end
  
  class Private < Route '/noauth/private'
    def get
      render "Welcome in the private part #{request.env['REMOTE_USER']}"
    end
  end

  class Private2 < Route '/noauth/private/again'
    def get
      render "Welcome in the private/again part #{request.env['REMOTE_USER']}"
    end
  end
  
end

Capcode.run( )