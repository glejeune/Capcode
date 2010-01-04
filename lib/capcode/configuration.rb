module Capcode
  class << self
    def configuration( args = {} ) #:nodoc:
      @configuration = config.merge({
        :port => args[:port]||Capcode.get(:port)||3000, 
        :host => args[:host]||Capcode.get(:host)||"0.0.0.0",
        :server => args[:server]||Capcode.get(:server)||nil,
        :log => args[:log]||Capcode.get(:log)||$stdout,
        :session => args[:session]||Capcode.get(:session)||{},
        :pid => args[:pid]||Capcode.get(:pid)||"#{$0}.pid",
        :daemonize => args[:daemonize]||Capcode.get(:daemonize)||false,
        :db_config => File.expand_path(args[:db_config]||Capcode.get(:db_config)||"database.yml"),
        :root => args[:root]||Capcode.get(:root)||File.expand_path(File.dirname($0)),
        :static => args[:static]||Capcode.get(:static)||args[:root]||File.expand_path(File.dirname($0)),
        :verbose => args[:verbose]||Capcode.get(:verbose)||false,
        :console => false
      })
    end
    def config
      @configuration ||= {}
    end
    
    # Set global configuration options
    #
    # Options :
    # * <tt>:port</tt> = Listen port (default: 3000)
    # * <tt>:host</tt> = Listen host (default: 0.0.0.0)
    # * <tt>:server</tt> = Server type (webrick, mongrel or thin)
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
    def set( key, value, opts = {} )
      if Hash === value
        opts = value
        value = nil
      end
      config[key] = value
      options[key] = opts
    end
    
    def get( key ) #:nodoc:
      config[key] || nil
    end
    
    def options
      @options ||= {}
    end
  end
end
