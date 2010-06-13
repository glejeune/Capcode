$:.unshift( "../lib" )
require 'capcode'
require 'rubygems'

module Capcode
  class Index < Route '/'
    def get
      render :markaby => :index, :layout => :forms
    end
  end
  
  class Action < Route "/action"
    def get( )
      @method = env["REQUEST_METHOD"]
      log.write( "#{@method}...\n" )
      @data = params["data"]
      render :markaby => :action, :layout => :forms
    end
   
    alias_method :post, :get
    
    def delete
      log.write( "DELETE...\n" )
      @method = "DELETE"
      @data = params["data"]
      render :markaby => :action, :layout => :forms
    end
    
    def put
      log.write( "PUT...\n" )
      @method = "PUT"
      @data = params["data"]
      render :markaby => :action, :layout => :forms
    end
    
  end
end

module Capcode::Views
  def forms
    html do
      body do
        yield
        
        form :method => "GET", :action => URL(Capcode::Action) do
          input :type => "text", :name => "data";
          input :type => "submit", :value => "GET"
        end
        
        form :method => "POST", :action => URL(Capcode::Action) do
          input :type => "text", :name => "data";
          input :type => "submit", :value => "POST"
        end

        form :method => "POST", :action => URL(Capcode::Action) do
          input :type => "hidden", :name => "_method", :value => "delete" ## <-- You need this 
          input :type => "text", :name => "data";
          input :type => "submit", :value => "DELETE"
        end

        form :method => "POST", :action => URL(Capcode::Action) do
          input :type => "hidden", :name => "_method", :value => "put" ## <-- You need this 
          input :type => "text", :name => "data";
          input :type => "submit", :value => "PUT"
        end
      end
    end
  end
  
  def index
    h1 "Hello !"
  end
  
  def action
    text "You send "; b @data; text " using a "; b @method; text " method!"; br
  end
  
end

#Capcode.run( )