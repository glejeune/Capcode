$:.unshift( "../lib" )
require 'capcode'
require 'capcode/render/static'

require 'coderay'
require 'rack/codehighlighter'

module Capcode
  set :static, "static"
  set :verbose, true
  set :server, :thin

  use Rack::Codehighlighter, :coderay, :element => "pre", :pattern => /\A:::(\w+)\s*\n/, :logging => false
  
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
  class Style < Route '/style'
    def get
      render :static => "coderay.css", :exact_path => false
    end
  end
end

Capcode.run( )