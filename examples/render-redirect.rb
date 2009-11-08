$:.unshift( "../lib" )
require 'capcode'
require 'capcode/render/redirect'

module Capcode
  class Index < Route '/'
    def get
      render :redirect => Hello
    end
  end  
  
  class Hello < Route '/hello'
    def get
      render :text => "Hello World!"
    end
  end  
end

Capcode.run( )