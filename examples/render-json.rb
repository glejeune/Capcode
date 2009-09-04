$:.unshift( "../lib" )
require 'capcode'
require 'capcode/render/json'

module Capcode
  class Index < Route '/'
    def get
      render :json => { :hello => "Hello World", :values => [1, 2, 3] }
    end
  end  
end

Capcode.run( )