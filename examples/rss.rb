$:.unshift( "../lib" )
require 'rubygems'
require 'capcode'
require 'capcode/render/xml'

## !! THIS IS JUSTE FOR THIS EXAMPLE !!
class Hash
  def method_missing( id, *a )
    self[id.id2name.to_sym]
  end
end

module Capcode
  class RSS < Route "/rss"
    def get
      @posts = [
        { :title => "Welcome", :body => "This is a RSS example for Capcode!", :iid => 1, :created_at => Time.now() },
        { :title => "Just For Fun", :body => "See more examples on the Capcode Website...", :iid => 2, :created_at => Time.now() },
      ]
      render :xml => :rss_view
    end
  end
end

module Capcode::Views
  def rss_view
    xml? :version => '1.0'
    rss :version => "2.0" do
      channel do
        title "Capcode News"
        description "Capcode Framework."
        link "http://example.com/"
        
        @posts.each do |post|
          item do
            title post.title
            link "http://example.com/posts/#{post.iid}"
            description post.body
            pubDate Time.parse(post.created_at.to_s).rfc822()
            guid "http://example.com/posts/#{post.iid}"
          end
        end
      end
    end
  end
end

Capcode.run()