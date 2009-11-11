$:.unshift( "../lib" )
require 'rubygems'
require 'capcode'
require 'capcode/base/sq'

class Basic < Capcode::Model 1.0
  def up
    create_table :stories do
      primary_key :id
      String :title
      String :body
      String :date
    end
  end
end

class UpdateBasic < Capcode::Model 1.1
  def up
    create_table :users do
      String :name
      String :password
    end
  end
  
  def down
    drop_table  :users
  end
end

class Story < Capcode::Base
  include Capcode::Resource  
end

module Capcode
  class HTTPError
    def r404(f)
      "Pas glop !!! #{f} est inconnu !!!"
    end
  end
  
  class Index < Route '/'
    def get
      r = "<html><body>"
      
      story = Story.all
      
      story.each do |s|
        r += "<h2>#{s[:title]}</h2><small>#{s[:date]} - <a href='#{URL( Remove, s[:id] )}'>Delete this entry</a></small><p>#{s[:body]}</p>"
      end
      
      r+"<hr /><a href='#{URL(Add)}'>Add a new entry</a></body></html>"
    end
  end
  
  class Remove < Route '/remove/([^\/]*)'
    def get( id )
      Story.filter(:id => id).delete
      redirect( Index )
    end
  end
  
  class Add < Route '/add'
    def get
      '
        <html><body>
          <h1>Add a new entry</h1>
          <form method="POST">
            Titre : <input type="text" name="title"><br />
            <textarea name="body"></textarea><br />
            <input type="submit">
          </form>
        </body></html>
      '
    end
    def post
      Story.insert( :title => params['title'], :body => params['body'], :date => Time.now.to_s )
      redirect( Index )
    end
  end
end

Capcode.run( :port => 3001, :host => "localhost", :db_config => "blog-sq.yml" )