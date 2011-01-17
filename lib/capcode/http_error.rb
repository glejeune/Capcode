module Capcode
  # HTTPError help you to create your own 404, 500 and/or 501 response
  # 
  # To create a custom 404 reponse, create a fonction HTTPError.r404 in
  # your application :
  #
  #   module Capcode
  #     class HTTPError
  #       def r404(f)
  #         "#{f} not found :("
  #       end
  #     end
  #   end
  #
  # the rXXX method can also receive a second optional parameter corresponding 
  # of the header's Hash :
  #
  #   module Capcode
  #     class HTTPError
  #       def r404(f, h)
  #         h['Content-Type'] = 'text/plain'
  #         "You are here ---> X (#{f} point)"
  #       end
  #     end
  #   end
  #
  # Do the same (r500, r501, r403) to customize 500, 501, 403 errors
  class HTTPError
    def initialize(app) #:nodoc:
      @app = app
    end
  
    def call(env) #:nodoc:
      status, headers, body = @app.call(env)
      if self.methods.include? "r#{status}"
        headers.delete('Content-Type') if headers.keys.include?('Content-Type')
        body = begin
          self.send( "r#{status}", env['REQUEST_PATH'], headers )
        rescue
          self.send( "r#{status}", env['REQUEST_PATH'] )
        end
        headers['Content-Length'] = body.length.to_s
        headers['Content-Type'] = "text/html" unless headers.keys.include?('Content-Type')
      end
      
      [status, headers, body]
    end
  end
end
