require 'rubygems'
require 'capcode'
require 'capcode/render/erb'
require 'capcode/render/static'
require 'faye'

module Capcode
  set :erb, "views"
  set :static, "public"
  use Faye::RackAdapter, :mount => '/comet'
  
  class Index < Route '/'
    def get
      @server = env['faye.server']
      render :erb => :index
    end
  end
  
  class Static < Route '/public/(.*)'
    def get( f )
      render :static => f
    end
  end
end

Capcode.run()