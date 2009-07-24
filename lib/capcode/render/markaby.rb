require "markaby"

Markaby::Builder.set(:indent, 2)

module Capcode
  module Markaby #:nodoc: all
    class Builder 
      include Views
    end
  end
  
  module Helpers
    def render_markaby( f, opts ) #:nodoc:
      f = f.to_s
      layout = opts.delete(:layout)||:layout
      
      mab = Markaby::Builder.new({}, self) { 
        if self.respond_to?(layout)
          self.send(layout.to_s) { |*args| 
            @@__ARGS__ = args
            self.send(f) 
          }
        else
          self.send(f) 
        end
      }
      mab.to_s  
    end
  end
end