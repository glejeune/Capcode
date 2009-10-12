require 'rubygems'
require 'test/unit'
require 'rack/test'
require 'sample.rb'

@@app = Capcode.application( :verbose => true )

class HomepageTest < Test::Unit::TestCase
  include Rack::Test::Methods
  
  def app
    @@app
  end
  
  def test_home
    get '/'
    
    assert_equal "http://example.org/", last_request.url
    assert last_response.ok?
    assert_equal "Hello World", last_response.body
  end
  
  def test_redirect
    get '/r'
    
    assert_equal "http://example.org/r", last_request.url
    follow_redirect!
    assert_equal "http://example.org/", last_request.url
    assert_equal "Hello World", last_response.body
  end
end