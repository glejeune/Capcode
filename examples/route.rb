$:.unshift( "../lib" )
require 'capcode'

module Capcode
  class HTTPError
    def r404(f, h)
      h['Content-Type'] = 'text/plain'
      "You are here ---> X (#{f} point)"
    end
  end
  
  # Access via GET /index
  class Index < Route 
    def get
      render "Hello Index!"
    end
  end
  
  # Acces via GET /foo_bar
  class FooBar < Route
    def get
      render "Hello FooBar!"
    end
  end
  
  # Access via GET /bar
  class Foo < Route '/bar'
    def get 
      render "Hello Foo!"
    end
  end
end

Capcode.run()