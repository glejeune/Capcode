module Capcode
  class << self
    # Add a before filter :
    #
    #   module Capcode
    #     before_filter :my_global_action
    #     before_filter :need_login, :except => [:Login]
    #     before_filter :check_mail, :only => [:MailBox]
    #     # ...
    #   end
    #
    # If the action return nil, the normal get or post will be executed, else no.
    # 
    def before_filter( action, opts = {} )
      Capcode::Filter.filters[action] = { }
      
      opts.each do |k, v|
        Capcode::Filter.filters[action][k] = v
      end
    end
  end
  
  class Filter #:nodoc:
    class << self
      def filters #:nodoc:
        @filters ||= { }
      end
      
      def execute( klass ) #:nodoc:
        klass_sym = "#{klass.class}".split( /::/)[-1].to_sym
        actions = []
        @filters.each do |action, data|
          if (data[:only] and data[:only].include?(klass_sym)) or 
             (data[:except] and not data[:except].include?(klass_sym)) or
             (data.keys.size == 0)
            actions << action
          end
        end

        klass.class.instance_eval{ include Capcode }
        rCod = nil
        actions.each do |a|
          rCod = klass.send( a )
        end
        
        return rCod
      end
    end
  end
end
