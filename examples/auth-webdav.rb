$:.unshift( "../lib" )
require 'capcode'
require 'capcode/render/webdav'

module Capcode
  
  # Render file from /Users/greg/temp !!!
  class WebDav < Route '/temp'
    def get
      http_authentication( :type => :digest, :realm => "My WebDAV Directory !!!" ) { 
        {"greg" => "toto"}
      }
      render :webdav => "/Users/greg/temp"
    end
    
    def method_missing(id, *a, &b)
      get
    end
  end  
  
  class Index < Route '/'
    def get
      render "WebDav server acces : <a href='#{URL(Capcode::WebDav)}'>#{URL(Capcode::WebDav)}</a>"
    end
  end
  
end

Capcode.run( )