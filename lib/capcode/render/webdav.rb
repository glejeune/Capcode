# From rack_dav
require 'builder'
require 'time'
require 'uri'
require 'rexml/document'
require 'webrick/httputils'

begin
  require 'rack_dav/builder_namespace'
  require 'rack_dav/http_status'
  require 'rack_dav/resource'
  require 'rack_dav/file_resource'
  require 'rack_dav/handler'
  require 'rack_dav/controller'
rescue LoadError => e
  raise MissingLibrary, "Rack_Dav could not be loaded (is it installed?): #{e.message}"
end 


module Capcode
  module Helpers
    
    def render_webdav( f, opts )
		  options = {
		    :resource_class => RackDAV::FileResource,
		    :root => f
		  }.merge(opts)
		  		
		  request = Rack::Request.new(env)
		  response = Rack::Response.new
    
		  begin
		    controller = RackDAV::Controller.new(request, response, options.dup)		    
		    controller.send(request.request_method.downcase)
		  rescue RackDAV::HTTPStatus::Status => status
		    response.status = status.code
		  end
      
		  # Strings in Ruby 1.9 are no longer enumerable.  Rack still expects the response.body to be
		  # enumerable, however.
		  response.body = [response.body] if not response.body.respond_to? :each
      
		  response.status = response.status ? response.status.to_i : 200
		  response.finish
		  
		  [response.status, response.header, response.body]
		end
  end
end