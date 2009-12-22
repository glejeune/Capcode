$:.unshift( "../lib" )
require 'capcode'
require 'rubygems'
require 'capcode/render/email'
require 'capcode/render/markaby'
require 'capcode/render/erb'
require 'capcode/render/static'
require 'graphviz'

module Capcode
  set :smtp, { :server => '127.0.0.1', :port => 25 }
  set :erb, "mail"
  set :static, "mail"
  
  class Index < Route '/'
    def get
      render :markaby => :index, :layout => :glop
    end
  end
  
  class SendMail < Route '/send'
    def get
      @time = Time.now
      render :email => {
        :from => 'you@yourdomain.com',
        :to => 'friend@hisdomain.com',
        :subject => "Mail renderer example...",
        
        :body => {
          :text => { :erb => :mail_text },
          :html => { :erb => :mail_html, :content_type => 'text/html; charset=UTF-8' }
        },
        :file => [
          { :data => :image, :filename => "hello.png", :mime_type => "image/png" },
          "rubyfr.png"
        ],
        :ok => { :erb => :ok },
        :error => { :redirect => Index }
      }
    end
  end
end

module Capcode::Views
  def glop
    html do
      body do
        yield
      end
    end
  end
  
  def index
    h1 "Send me an email"
    a "Send mail", :href => URL(Capcode::SendMail)
  end
  
  def image
    GraphViz::new( "G" ) { |g|
      g.hello << g.world
      g.bonjour - g.monde
      g.hola > g.mundo
      g.holla >> g.welt
    }.output( :png => String )
  end
end

Capcode.run( )