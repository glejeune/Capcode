$:.unshift( "../lib" )
require 'capcode'
require 'capcode/render/erb'
Capcode::Helpers.erb_path="erb"

module Capcode
  class Index < Route '/'
    def get
      render :erb => :cf, :layout => :cf_layout
    end
  end  
end

Capcode.run( )