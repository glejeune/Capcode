$:.unshift( "../lib" )
require 'rubygems'
require 'capcode'
require 'capcode/base/couchdb'
require 'capcode/render/markaby'

class User < Capcode::Base
  include Capcode::Resource
  
  property :login, String
  property :passwd, String
  
  has_many :stories
end

class Story < Capcode::Base
  include Capcode::Resource
  
  property :title, String
  property :body, String
  property :create_at, String
  
  property :user_id, String
  belongs_to :user

  default_sort :create_at
end

module Capcode
  class HTTPError
    def r404(f)
      @file = f
    end
  end
  
  class Style < Route '/styles.css'
    STYLE = File.read(__FILE__).gsub(/.*__END__/m, '')

    def get
      @response['Content-Type'] = 'text/css; charset=utf-8'
      STYLE
    end
  end
      
  class Index < Route '/'
    def get
      @story = Story.find( :all )
      
      render( :markaby => :home, :layout => :my_layout )
    end
  end
  
  class Remove < Route '/remove/([^\/]*)/(.*)'
    def get( id, rev )
      Story.delete(id, rev)
      redirect( Index )
    end
  end
  
  class Add < Route '/add'
    def get
      if session[:user]
        @story = Story.new()
        render( :markaby => :add, :layout => :my_layout )
      else
        redirect( Login )
      end
    end
    def post
      if session[:user]
        s = Story.create( :title => params['title'], :body => params['body'], :create_at => Time.now, :user_id => session[:user] )
        redirect( Index )
      else
        redirect( Login )
      end
    end
  end
  
  class Edit < Route '/edit/(.*)'
    def get( id )
      if session[:user]
        @story = Story.find( id )
        render( :markaby => :add, :layout => :my_layout )
      else
        redirect( Index )
      end
    end
    def post( id )
      # story = Story.find( params['id'] )
      story = Story.find( id )
      story.title = params['title']
      story.body = params['body']
      story.save
      
      redirect( Index )
    end
  end
  
  class Login < Route '/login'
    def get
      if session[:user]
        redirect( Index )
      else
        render( :markaby => :login, :layout => :my_layout )
      end
    end
    def post
      u = User.find_by_login_and_passwd( params['login'], params['passwd'] )
      unless u.nil?
        session[:user] = u.id
      end      
      redirect( Index )
    end
  end
  
  class Logout < Route '/logout'
    def get
      session[:user] = nil
      redirect( Index )
    end
  end
end

module Capcode::Views
  def r404
    p "Pas glop !!! #{@file} est inconnu !!!"
  end
  
  def home
    @story.each do |s|
      h2 s.title
      p.info do
        _post_menu(s)
        text " #{s.create_at} by " #.strftime('%B %M, %Y @ %H:%M ')
        i s.user.login
      end
      text s.body
    end
  end
  
  def add
    form :method => "POST" do
      text "Titre :" 
      input :type => "text", :name => "title", :value => @story.title; br
      textarea :name => "body" do; @story.body; end; br
      input :type => "submit"
      # input :type => "hidden", :name => "id", :value => @story.id
    end
  end
  
  def login
    form :method => "POST" do
      table do
        tr do
          td "Login :"
          td {input :type => "text", :name => "login"}
        end
        tr do
          td "Password :"
          td {input :type => "text", :name => "passwd"}
        end
      end
      input :type => "submit", :value => "Login"
    end
  end
  
  def my_layout
    html do
      head do
        title 'My Blog'
        link :rel => 'stylesheet', :type => 'text/css', :href => '/styles.css', :media => 'screen'
      end
      body do
        h1 { a 'My Blog', :href => URL(Capcode::Index) }
        
        div.wrapper! do
          yield
        end
        
        p.footer! do
          if session[:user]
            a 'New', :href => URL(Capcode::Add)
            text "|"
            a "Logout", :href => URL(Capcode::Logout)
          else
            a 'Login', :href => URL(Capcode::Login)
          end
          text ' &ndash; Powered by '
          a 'Capcode', :href => 'http://capcode.rubyforge.org'
        end
      end
    end
  end
  
  def _post_menu(post)
    if session[:user]
      text '['
      a "Del", :href => URL( Capcode::Remove, post.id, post.rev )
      text '|'
      a "Edit", :href => URL( Capcode::Edit, post.id )
      text ']'
    end
  end
  
end

#Capcode.run( :port => 3001, :host => "localhost", :db_config => "blog-couchdb.yml" ) do |c|
#  admin = User.find_by_login( "admin" )
#  if admin.nil?
#    puts "Create admin user..."
#    admin = User.create( :login => "admin", :passwd => "admin" )
#  end
#  puts "Admin user : \n\tlogin = #{admin.login}\n\tpassword = #{admin.passwd}"
#end

__END__
* {
  margin: 0;
  padding: 0;
}
 
body {
  font: normal 14px Arial, 'Bitstream Vera Sans', Helvetica, sans-serif;
  line-height: 1.5;
}
 
h1, h2, h3, h4 {
  font-family: Georgia, serif;
  font-weight: normal;
}
 
h1 {  
  background-color: #EEE;
  border-bottom: 5px solid #f06000;
  outline: 5px solid #ab250c;       
  font-weight: normal;
  font-size: 3em;  
  padding: 0.5em 0;
  text-align: center;
}
 
h1 a { color: #143D55; text-decoration: none }
h1 a:hover { color: #143D55; text-decoration: underline }
 
h2 {
  font-size: 2em;
  color: #287AA9;  
}
 
#wrapper { 
  margin: 3em auto;
  width: 700px;
}
 
p {
  margin-bottom: 1em;
}
 
p.info, p#footer {
  color: #999;
  margin-left: 1em;
}
 
p.info a, p#footer a {
  color: #999;
}
 
p.info a:hover, p#footer a:hover {
  text-decoration: none;
}
 
a {
  color: #6F812D;
}
 
a:hover {
  color: #9CB441;
}
 
hr {
  border-width: 5px 0;
  border-style: solid;     
  border-color: #9CB441;
  border-bottom-color: #6F812D;
  height: 0;   
}
 
p#footer {    
  font-size: 0.9em;
  margin: 0;      
  padding: 1em;
  text-align: center;
}
 
label {  
  display: inline-block;
  width: 100%;
}
 
input, textarea {     
  margin-bottom: 1em;
  width: 200px;  
}
 
input.submit {
  float: left;
  width: auto;
}
 
textarea {
  font: normal 14px Arial, 'Bitstream Vera Sans', Helvetica, sans-serif;
  height: 300px;
  width: 400px;
}