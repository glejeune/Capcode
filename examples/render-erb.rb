$:.unshift( "../lib" )
require 'capcode'
require 'capcode/render/erb'
#Capcode::Helpers.erb_path="erb"

module Capcode
  set :erb, "erb"
  
  class Index < Route '/'
    def get
      @time = Time.now
      render :erb => :cf, :layout => :cf_layout
    end
  end  
end

Capcode.run( )