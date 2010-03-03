$:.unshift( "../lib" )
require 'capcode'

module Capcode
  class HTTPError
    def r404(f)
      "Pas glop !!! #{f} est inconnu !!!"
    end
  end
  
  class Index < Route
    def get
      render "Hello Index!"
    end
  end
  
  class MainTruc < Route
    def get
      render "Hello Main!"
    end
  end
  
  class Pipo < Route '/not_pipo'
    def get 
      render "Hello Pipo!"
    end
  end
end

Capcode.run()