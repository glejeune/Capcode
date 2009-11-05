$:.unshift( "../lib" )
require 'capcode'
require 'capcode/render/erb'
#Capcode::Helpers.erb_path="erb"
require 'rack/bug'

module Capcode
  set :erb, "erb"
  use Rack::Bug
  
  class Index < Route '/'
    def get
      @time = Time.now
      render :erb => :cf, :layout => :cf_layout
    end
  end  
end

Capcode.run( )