$:.unshift( "../lib" )
require 'capcode'

module Capcode
  class HTTPError
    def r404(f, h)
      h['Content-Type'] = 'text/plain'
      "You are here ---> X (#{f})"
    end
  end
  
  class Home < Route '/'
    def get
      render :markaby => :home
    end
  end
  
  # Access via GET /index
  class Index < Route
    def get
      render :markaby => :index
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
  
  class RegexpOne < Route '/one/(.*)'
    def get(x)
      render "RegexpOne with '#{x}'"
    end
  end
  
  class RegexpTwo < Route '/two/([^\/]*)/two'
    def get(x)
      render "RegexpTwo with '#{x}'"
    end
  end

  class RegexpThree < Route '/three/with/([^\/]*)/and/(.*)', '/three/(.*)'
    def get(x, y)
      render "RegexpThree with '#{x}' and '#{y}'"
    end
  end
  
end

module Capcode::Views
  def home
    html do
      body do
        a "Index", :href => URL(Capcode::Index); br;
        a "Home", :href => URL(Capcode::Home); br;
      end
    end
  end
  def index
    html do
      body do
        a "FooBar", :href => URL(Capcode::FooBar); br;
        a "Foo", :href => URL(Capcode::Foo); br;
        a "RegexpOne", :href => URL(Capcode::RegexpOne, "Hello World"); br;
        a "RegexpTwo", :href => URL(Capcode::RegexpTwo, "Hello World"); br;
        a "RegexpThree", :href => URL(Capcode::RegexpThree, "Hello", "World"); br;
        a "RegexpThree (again)", :href => URL(Capcode::RegexpThree, "Hello World"); br;
      end
    end
  end
end

Capcode.run()