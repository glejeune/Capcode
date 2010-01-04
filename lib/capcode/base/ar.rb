begin
  require 'active_record'
rescue LoadError => e
  raise Capcode::MissingLibrary, "ActiveRecord could not be loaded (is it installed?): #{e.message}"
end

module Capcode
  # This module contains the resources needed in a model
  module Resource
  end
  
  # This class allow you to define models
  Base = ActiveRecord::Base
  
  # Schema info
  class SchemaInfo < Base
  end
  
  class << self
    # This class allow you to define models
    def Model( n )
      @final = [n, @final.to_f].max
      m = (@migrations ||= [])
      Class.new(ActiveRecord::Migration) do
        meta_def(:version) { n }
        meta_def(:inherited) { |k| m << k }
      end
    end
    
    def db_connect( dbfile, logfile ) #:nodoc:
      dbconfig = YAML::load(File.open(dbfile)).keys_to_sym
      version = dbconfig.delete(:schema_version) { |_| @final }
      
      ActiveRecord::Base.establish_connection(dbconfig)
      ActiveRecord::Base.logger = Logger.new(logfile)
      
      if @migrations
        unless SchemaInfo.table_exists?
          ActiveRecord::Schema.define do
            create_table SchemaInfo.table_name do |t|
              t.column :version, :float
            end
          end
        end
        si = SchemaInfo.find(:first) || SchemaInfo.new(:version => 0)
        @migrations.each do |k|
          k.migrate(:up) if si.version < k.version and k.version <= version
          k.migrate(:down) if si.version >= k.version and k.version > version
        end
        si.update_attributes(:version => version)
      end
    end
  end
end