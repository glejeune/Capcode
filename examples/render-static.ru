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

puts __FILE__

## WARNING : when using rackup, :root default is the rackup directory (eg. /usr/bin or something like that) !
run Capcode.application( :static => "static", :verbose => true, :root => File.expand_path(File.dirname(__FILE__)) )
