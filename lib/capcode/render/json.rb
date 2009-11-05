begin
  require 'json'
rescue LoadError => e
  raise MissingLibrary, "Json could not be loaded (is it installed?): #{e.message}"
end

module Capcode
  module Helpers
    def render_json( f, opts ) #:nodoc:
      @response['Content-Type'] = 'application/json'
      f.to_json
    end
  end
end