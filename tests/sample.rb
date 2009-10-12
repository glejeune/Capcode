require 'rubygems'
require 'capcode'

module Capcode
  class Index < Route '/'
    def get
      render "Hello World"
    end
  end
  
  class Redir < Route '/r'
    def get
      redirect( Index )
    end
  end
end
