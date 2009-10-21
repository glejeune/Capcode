module Capcode
  class << self
    # Set global configuration options
    #
    # Options :
    # * <tt>:port</tt> = Listen port (default: 3000)
    # * <tt>:host</tt> = Listen host (default: 0.0.0.0)
    # * <tt>:server</tt> = Server type (webrick or mongrel)
    # * <tt>:log</tt> = Output logfile (default: STDOUT)
    # * <tt>:session</tt> = Session parameters. See Rack::Session for more informations
    # * <tt>:pid</tt> = PID file (default: $0.pid)
    # * <tt>:daemonize</tt> = Daemonize application (default: false)
    # * <tt>:db_config</tt> = database configuration file (default: database.yml)
    # * <tt>:static</tt> = Static directory (default: the working directory)
    # * <tt>:root</tt> = Root directory (default: directory of the main.rb) -- This is also the working directory !
    # * <tt>:verbose</tt> = run in verbose mode
    # * <tt>:auth</tt> = HTTP Basic Authentication options 
    #
    # It can exist specifics options depending on a renderer, a helper, ...
    # 
    # Example : 
    #
    #   module Capcode
    #     set :erb, "/path/to/erb/files"
    #     ...
    #   end
    def set( key, value )
      config[key] = value
    end
    
    def get( key ) #:nodoc:
      config[key] || nil
    end
    
    def config
      @configuration ||= {}
    end
  end
end
