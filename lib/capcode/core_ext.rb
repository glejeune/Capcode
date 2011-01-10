class Object
  def meta_def(m,&b) #:nodoc:
    (class<<self;self end).send(:define_method,m,&b)
  end
end

class Regexp
  def number_of_captures #:nodoc:
    c, x = 0, self.source.dup.gsub( /\\\(/, "" ).gsub( /\\\)/, "" )
    while( r = /(\([^\)]*\))/.match( x ) )
      c, x = c+1, r.post_match
    end
    c
  end
  
  # From http://facets.rubyforge.org/apidoc/api/core/classes/Regexp.html
  def arity #:nodoc:
    self.source.scan( /(?!\\)[(](?!\?[#=:!>-imx])/ ).length
  end
end

class Hash
  def keys_to_sym #:nodoc:
    self.each do |k, v|
      self.delete(k)
      self[k.to_s.to_sym] = v
    end
  end
end

require 'active_support'

class String
  def underscore
    ActiveSupport::Inflector.underscore( self )
  end
end
