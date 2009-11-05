begin
  require 'markaby'
rescue LoadError => e
  raise MissingLibrary, "Markaby could not be loaded (is it installed?): #{e.message}"
end

Markaby::Builder.set(:indent, 2)

module Capcode
  class Mab < Markaby::Builder
    include Views
  end
  
  module Helpers
    def render_markaby( f, opts ) #:nodoc:
      f = f.to_s
      layout = opts.delete(:layout)||:layout

      __mab = Mab.new({}, self) { 
        if self.respond_to?(layout)
          self.send(layout.to_s) { |*args| 
            #@@__ARGS__ = args
            Capcode::Helpers.args = args
            self.send(f) 
          }
        else
          self.send(f) 
        end
      }
      __mab.to_s  
    end
  end
end
