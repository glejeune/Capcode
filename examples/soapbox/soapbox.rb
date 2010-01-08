require 'rubygems'
require 'capcode'
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
end

Capcode.run( )