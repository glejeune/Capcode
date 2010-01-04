begin
  require 'sequel'
  Sequel.extension :migration
  Sequel.extension :inflector
rescue LoadError => e
  raise Capcode::MissingLibrary, "Sequel could not be loaded (is it installed?): #{e.message}"
end

module Capcode
  # This module contains the resources needed in a model
  module Resource
  end
  
  # This class allow you to define models
  class Base
    def self.method_missing( name, *args, &block )
      if block_given?
        Capcode::db[self.to_s.tableize.to_sym].__send__(name.to_sym, *args, &block)
      else
        Capcode::db[self.to_s.tableize.to_sym].__send__(name.to_sym, *args)
      end
    end
  end
  
  class << self
    # This class allow you to define models
    def Model( n )
      @final = [n, @final.to_f].max
      m = (@migrations ||= [])
      Class.new(Sequel::Migration) do
        meta_def(:version) { n }
        meta_def(:inherited) { |k| m << k }
      end
    end
    
    def db
      @db ||= Sequel.connect(@dbconfig)
    end
    
    def db_connect( dbfile, logfile )
      @dbconfig = YAML::load(File.open(dbfile)).keys_to_sym
      @dbconfig[:adapter] = "sqlite" if @dbconfig[:adapter] == "sqlite3"
      version = @dbconfig.delete(:schema_version) { |_| @final }
      
      if @migrations
        Capcode::db.create_table? :schema_table do
          Float :version
        end
        si = Capcode::db[:schema_table].first || (Capcode::db[:schema_table].insert(:version => 0); {:version => 0})
        @migrations.each do |k|
          k.apply(Capcode::db, :up) if si[:version] < k.version and k.version <= version
          k.apply(Capcode::db, :down) if si[:version] >= k.version and k.version > version
        end
        Capcode::db[:schema_table].where(:version => si[:version]).update(:version => version)
      end
    end
  end
end
