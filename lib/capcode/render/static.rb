module Capcode
  module Helpers
    def render_static( f, opts = { :exact_path => true } ) #:nodoc:
      if Capcode.static.nil? or f.include? '..'
        return [403, {}, '403 - Invalid path']
      end
      
      # Update options
      opts = (Capcode.options[:static] || {}).merge(opts)
      
      if !opts.keys.include?(:exact_path) or opts[:exact_path] == true
        redirect File.join( static[:uri], f )
      else
        File.read( File.join( static[:path], f ) ).to_s
      end
    end
  end
end