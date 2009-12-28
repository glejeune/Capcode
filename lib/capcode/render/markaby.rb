begin
  require 'markaby'
rescue LoadError => e
  raise MissingLibrary, "Markaby could not be loaded (is it installed?): #{e.message}"
end

module Capcode
  class Mab < Markaby::Builder
    include Views
  end
  
  module Helpers
    def render_markaby( f, opts = {} ) #:nodoc:
      f = f.to_s
      layout = opts.delete(:layout)||:layout

      # Update options
      (Capcode.options[:markaby] || {}).merge(opts).each do |k, v|
        Markaby::Builder.set(k, v)
      end
      
      assigns = {}
      self.instance_variables.delete_if {|x| ["@response", "@env", "@request"].include?(x) }.each do |ivar|
        assigns[ivar.gsub( /^@/, "" )] = self.instance_variable_get(ivar)
      end

      __mab = Mab.new(assigns.merge( opts ), self) { 
        if self.respond_to?(layout)
          self.send(layout.to_s) { |*args| 
            # @@__ARGS__ = args
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
