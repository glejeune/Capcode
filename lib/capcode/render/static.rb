module Capcode
  module Helpers
    def render_static( f, opts = {} ) #:nodoc:
      # Update options
      opts = { :exact_path => true }.merge(opts)
      opts = (Capcode.options[:static] || {}).merge(opts)
      
      # Update Content-Type
      @response['Content-Type'] = opts[:content_type] if opts.keys.include?(:content_type)
      
      # Path with ".." not allowed
      if Capcode.static.nil? or f.include? '..'
        return [403, {}, '403 - Invalid path']
      end
      
      
      if !opts.keys.include?(:exact_path) or opts[:exact_path] == true
        redirect File.join( static[:uri], f )
      else
        File.read( File.join( static[:path], f ) ).to_s
      end
    end
  end
end