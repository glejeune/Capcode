$:.unshift( "../lib" )
require 'capcode'
require 'capcode/render/haml'
require 'capcode/render/sass'
Capcode::Helpers.haml_path="haml"
Capcode::Helpers.sass_path="haml"

module Capcode
  class Index < Route '/'
    def get
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