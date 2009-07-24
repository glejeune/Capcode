$:.unshift( "../lib" )
require 'capcode'

module Capcode
  class HTTPError
    def r404(f)
      "#{f} not found !!!"
    end
  end
  
  class Index < Route '/'
    def get
      redirect( Hello, session[:user] )
    end
  end
  
  class Hello < Route '/hello/(.*)'
    def get( you )
      if you.nil?
        redirect( WhoAreYou )
      else
        " 
          Hello #{you}<br />
          Clic <a href='#{URL(Hello)}'>here</a> if hou want to change your name
        "
      end
    end
  end
  
  class WhoAreYou < Route '/who_are_you'
    def get
      '
        Please, enter your name :<br />
        <form method="POST">
          <input type="text", name="user"><br />
          <input type="submit">
        </form>
      '
    end
    def post
      session[:user] = params['user']
      redirect( Index )
    end
  end
end

Capcode.run( :port => 3000, :host => "localhost" )