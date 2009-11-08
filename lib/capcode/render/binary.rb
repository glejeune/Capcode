module Capcode
  module Helpers
    def render_binary( f, opts ) #:nodoc:
      @response['Content-Type'] = opts[:content_type]||opts['Content-Type']||"binary/octet-stream"
      self.send(f) 
    end
  end
end