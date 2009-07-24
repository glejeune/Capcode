module Capcode
  module Helpers
    def render_static( f, _ ) #:nodoc:
      if Capcode.static.nil? or f.include? '..'
        return [403, {}, '403 - Invalid path']
      end
      redirect File.join( Capcode.static, f )
    end
  end
end