$:.unshift( "../lib" )
require 'capcode'
require 'capcode/render/mustache'
require 'capcode/render/sass'

module Capcode
  set :mustache, "mustache"
  
  class Index < Route '/'
    def get
      @time = Time.now
      render :mustache => :with_class
    end
  end
  
  class WithoutClass < Route '/without'
    def get
      render :mustache => :without_class, :time => Time.now
    end
  end  
end

module Capcode::Views
  class WithClass < Mustache
    def time
      @time
    end
  end
end

Capcode.run( )