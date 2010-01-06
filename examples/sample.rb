$:.unshift( "../lib" )
require 'capcode'
require 'rubygems'
require 'capcode/render/markaby'
require 'capcode/render/haml'
require 'capcode/render/json'
require 'capcode/render/erb'

module Capcode
  module Helpers
    def bold( &b )
      "<b>"+yield+"</b>"
    end
  end
end

module Capcode
  set :haml, "haml"
  set :erb, "erb"
  
  class HTTPError
    def r404(f)
      "Pas glop !!! #{f} est inconnu !!!"
    end
  end
  
  class Hello < Route '/hello/(.*)'
    def get( you )
      @you = you
      @you = "you" if you.nil?
      
      session = { :user => @you }
      
      render( :haml => :m_hello )
    end
  end
  
  class Redir < Route '/r'
    def get
      redirect( Hello, "Greg" )
    end
  end
  
  class Glop < Route '/glop/(.*)', '/glop/code/([^\/]*)/(.*)'
    def get( r, v )
      render( :text => "Glop receive #{r}, type #{r.class} and #{v}, type #{v.class} from #{URL(Glop)}" )
    end
  end
  
  class Js < Route '/toto'
    def get
      render( :json => { :some => 'json', :stuff => ['here'] } )
    end
  end
  
  class Env < Route '/env'
    def get
      x = env.map do |k,v|
        "#{k} => #{v}"
      end.join( "<br />\n" )      
      render( :text => x )
    end
  end
  
  class ContentFor < Route '/cf'
    def get
      @time = Time.now
      render( :erb => :cf, :layout => :cf_layout )
    end
  end
end

module Capcode::Views
  def cf_layout
    html do
      head do
        yield :header
      end
      body do
        yield :content
      end
    end
  end
  
  def cf
    content_for :header do
      title "This is the title!"
    end
    
    content_for :content do
      p "this is the content!"
    end
  end
  
  def layout
    html do
      head do
        title "Use a layout ;)"
      end
      body do
        yield
      end
    end
  end
  
  def m_hello
    p do 
      text "Hello " 
      b @you
      text " it's '#{Time.now} !"
    end
  end
end

Capcode.run( :port => 3001, :host => "localhost", :static => "static" )