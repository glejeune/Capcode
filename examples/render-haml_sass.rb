$:.unshift( "../lib" )
require 'capcode'
require 'capcode/render/haml'
require 'capcode/render/sass'
#Capcode::Helpers.haml_path="haml"
#Capcode::Helpers.sass_path="haml"

module Capcode
  set :haml, "haml" #, { :format => :html4 }
  set :sass, "haml"
  
  class Index < Route '/'
    def get
      @time = Time.now
      render :haml => :cf, :layout => :cf_layout
    end
  end
  
  class CSS < Route '/style.css'
    def get
      render :sass => :style
    end
  end
end

Capcode.run( )