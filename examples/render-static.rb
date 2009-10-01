$:.unshift( "../lib" )
require 'capcode'
require 'capcode/render/static'

module Capcode
  class Index < Route '/'
    def get
      render :static => "index.html"
    end
  end  
  class Path < Route '/path'
    def get
      render :static => "index.html", :exact_path => false
    end
  end  
end

Capcode.run( :static => "static", :verbose => true )