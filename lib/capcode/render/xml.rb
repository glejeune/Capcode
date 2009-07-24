class XML #:nodoc: all
  class TagError < ArgumentError
  end
  
  class DSL
    def initialize( helper, &block )
      @__x_d_level = 0
      @__x_d_helper = helper
      @__x_d_helper.instance_variables.each do |ivar|
        self.instance_variable_set(ivar, @__x_d_helper.instance_variable_get(ivar))
      end
      @__x_d_builder = ""
      instance_eval(&block) if block
    end

    def __
      " "*@__x_d_level
    end

    def _(x)
      @__x_d_builder << __ << x << "\n"
    end
    
    def tag!(sym, *args, &block)
      tag = {
        :bra => "<",
        :ket => " />",
        :name => sym.id2name,
        :close => block_given?(),
        :attrs => "",
        :value => ""
      }
              
      args.each do |a|
        if a.class == Hash
          a.each do |k, v|
            tag[:attrs] << " #{k.to_s}='#{v}'"
          end
        elsif a.class == String
          tag[:close] = true
          tag[:value] << a << "\n"
        end
      end
      
      if tag[:name].match( /\?$/ )
        tag[:name].gsub!( /\?$/, "" )
        tag[:bra] = "<?"
        tag[:ket] = "?>"
        
        if tag[:close] == true
          raise XML::TagError, "Malformated traitment tag!"
        end
      end

      @__x_d_builder << __ << tag[:bra] << "#{tag[:name]}#{tag[:attrs]}"
      if tag[:close]
        @__x_d_builder << ">\n"
      else
        @__x_d_builder << tag[:ket] << "\n"
      end
      
      @__x_d_level += 2
      
      @__x_d_builder << __ << tag[:value] if tag[:value].size > 0
      instance_eval(&block) if block
      
      @__x_d_level -= 2
      
      if tag[:close]
        @__x_d_builder << __ << "</#{tag[:name]}>\n"
      end
    end
    
    def cdata( x = "", &block )
      @__x_d_builder << __ << "<![CDATA["
      if x.match( /\n/ ) or block
        @__x_d_level += 2
        @__x_d_builder << "\n" << __ << x << "\n" if x.size > 0
        instance_eval(&block) if block
        @__x_d_level -= 2
        @__x_d_builder << __ 
      else
        @__x_d_builder << x if x.size > 0
      end
      @__x_d_builder << "]]>\n"
    end
    
    def to_s
      @__x_d_builder
    end
    
    def method_missing(sym, *args, &block)
      if @__x_d_helper.respond_to?(sym, true)
        @__x_d_helper.send(sym, *args, &block)
      elsif instance_variables.include?(ivar = "@__x_d_#{sym}")
        instance_variable_get(ivar)
      elsif !@__x_d_helper.nil? && @__x_d_helper.instance_variables.include?(ivar)
        @__x_d_helper.instance_variable_get(ivar)
      else
        tag!(sym, *args, &block)
      end
    end
  end
end

module Capcode
  class XML::DSL #:nodoc:
    include Views
  end
  
  module Helpers
    def render_xml( f, _ ) #:nodoc:
      r = XML::DSL.new( self ) do
        self.send(f.to_s)
      end
      r.to_s
    end
  end
end