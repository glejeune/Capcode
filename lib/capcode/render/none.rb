module Capcode
  module Helpers
    def render_none( f = "", _ ) #:nodoc:
      return [204, {}, f]
    end
  end
end