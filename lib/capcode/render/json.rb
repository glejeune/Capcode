require 'json'

module Capcode
  module Helpers
    def render_json( f, opts ) #:nodoc:
      @response['Content-Type'] = 'application/json'
      f.to_json
    end
  end
end