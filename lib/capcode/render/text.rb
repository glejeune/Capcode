module Capcode
  module Helpers
    def render_text( f, _ ) #:nodoc:
      @response['Content-Type'] = 'text/plain'
      f
    end
  end
end