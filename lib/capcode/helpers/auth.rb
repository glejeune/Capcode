# Because this helper was trully inspired by this post :
# http://www.gittr.com/index.php/archive/sinatra-basic-authentication-selectively-applied/
# and because the code in this post was extracted out of Wink, this file follow the 
# Wink license :
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#  
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#  
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module Capcode
  module Helpers
    module Authorization
      def auth #:nodoc:
        if @auth_type == :basic
          @auth ||= Rack::Auth::Basic::Request.new(env)
        else
          @auth ||= Rack::Auth::Digest::Request.new(env)
        end
      end
      
      def basic_unauthorized!(realm) #:nodoc:
        response['WWW-Authenticate'] = %(Basic realm="#{realm}")
        throw :halt, [ 401, {}, 'Authorization Required' ]
      end

      def digest_unauthorized!(realm, opaque) #:nodoc:
        response['WWW-Authenticate'] = %(Digest realm="#{realm}", qop="auth", nonce="#{Rack::Auth::Digest::Nonce.new.to_s}", opaque="#{H(opaque)}") 
        throw :halt, [ 401, {}, 'Authorization Required' ]
      end
      
      def H(data) #:nodoc:
        ::Digest::MD5.hexdigest(data)
      end
      
      def KD(secret, data) #:nodoc:
        H([secret, data] * ':')
      end

      def A1(auth, password) #:nodoc:
        [ auth.username, auth.realm, password ] * ':'
      end

      def A2(auth) #:nodoc:
        [ auth.method, auth.uri ] * ':'
      end

      def digest(auth, password) #:nodoc:
        password_hash = H(A1(auth, password))

        KD(password_hash, [ auth.nonce, auth.nc, auth.cnonce, "auth", H(A2(auth)) ] * ':')
      end
      
      def digest_authorize( ) #:nodoc:
        h = @authorizations.call( )
        
        user = auth.username
        pass = h[user]||false

        (pass && (digest(auth, pass) == auth.response))
      end

      def basic_authorize(username, password) #:nodoc:
        h = @authorizations.call( )
        
        user = username
        pass = h[user]||false
        
        (pass == password)
      end
            
      def bad_request! #:nodoc:
        throw :halt, [ 400, {}, 'Bad Request' ]
      end
      
      def authorized? #:nodoc:
        request.env['REMOTE_USER']
      end
      
      # Allow you to add and HTTP Authentication (Basic or Digest) to a controller
      # 
      # Options :
      # * <tt>:type</tt> : Authentication type (<tt>:basic</tt> or <tt>:digest</tt>) - default : <tt>:basic</tt>
      # * <tt>:realm</tt> : realm ;) - default : "Capcode.app"
      # * <tt>:opaque</tt> : Your secret passphrase. You MUST set it if you use Digest Auth - default : "opaque"
      #
      # The block must return a Hash of username => password like that :
      #   {
      #     "user1" => "pass1",
      #     "user2" => "pass2",
      #     # ...
      #   }
      def http_authentication( opts = {}, &b )
        @auth = nil
        
        @auth_type = opts[:type]||:basic
        realm = opts[:realm]||"Capcode.app"
        opaque = opts[:opaque]||"opaque"
        @authorizations = b
        
        return if authorized?
        
        if @auth_type == :basic
          basic_unauthorized!(realm) unless auth.provided?
          bad_request! unless auth.basic?
          basic_unauthorized!(realm) unless basic_authorize(*auth.credentials)
        else
          digest_unauthorized!(realm, opaque) unless auth.provided?
          bad_request! unless auth.digest?
          digest_unauthorized!(realm, opaque) unless digest_authorize
        end        
        
        request.env['REMOTE_USER'] = auth.username
      end
    end
  end
end