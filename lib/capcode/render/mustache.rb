begin
  require 'mustache'
rescue LoadError => e
  raise MissingLibrary, "Mustache could not be loaded (is it installed?): #{e.message}"
end

module Capcode
  module Helpers
    def render_mustache( f, opts = {} ) #:nodoc:
      mustache_path = Capcode::Configuration.get( :mustache ) || Capcode.static() 
      
      name = Mustache.classify(f.to_s)
      
      if Capcode::Views.const_defined?(name)
        klass = Capcode::Views.const_get(name)
      else
        klass = Mustache
        klass.template_file = mustache_path + "/" + f.to_s + ".mustache"
      end
      
      klass.template_extension = 'mustache'
      klass.template_path = mustache_path
      
      instance = klass.new
      
      instance_variables.each do |name|
        instance.instance_variable_set(name, instance_variable_get(name))
      end

      opts.each do |k, v|
        instance[k] = v
      end
      
      instance.to_html
    end
  end
end