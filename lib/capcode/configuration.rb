module Capcode
  class << self
    def set(key, value, opts = {}); Configuration.set(key, value, opts); end
  end
  
  class Configuration
    class << self
      def configuration( args = {} ) #:nodoc:
        @configuration = config.merge({
          :port => args[:port]||Capcode::Configuration.get(:port)||3000, 
          :host => args[:host]||Capcode::Configuration.get(:host)||"0.0.0.0",
          :server => args[:server]||Capcode::Configuration.get(:server)||nil,
          :log => args[:log]||Capcode::Configuration.get(:log)||$stdout,
          :session => args[:session]||Capcode::Configuration.get(:session)||{},
          :pid => args[:pid]||Capcode::Configuration.get(:pid)||"#{$0}.pid",
          :daemonize => args[:daemonize]||Capcode::Configuration.get(:daemonize)||false,
          :db_config => File.expand_path(args[:db_config]||Capcode::Configuration.get(:db_config)||"database.yml"),
          :root => args[:root]||Capcode::Configuration.get(:root)||File.expand_path(File.dirname($0)),
          :static => args[:static]||Capcode::Configuration.get(:static)||args[:root]||File.expand_path(File.dirname($0)),
          :verbose => args[:verbose]||Capcode::Configuration.get(:verbose)||false,
          :console => false
        })
      end
      def config #:nodoc:
        @configuration ||= {}
      end
      
      def print_debug
        Capcode::Configuration.config.each do |k, v|
          puts "** [CONFIG] : #{k} = #{v}"
        end
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
      
      def get( key = nil )
        if key.nil?
          config
        else
          config[key] || nil
        end
      end
      
      def options
        @options ||= {}
      end
    end
  end
end
