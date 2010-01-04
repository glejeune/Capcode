require 'rubygems'
begin
  require 'mongoid'
rescue LoadError => e
  raise Capcode::MissingLibrary, "Mongoid could not be loaded (is it installed?): #{e.message}"
end
require 'yaml'
require 'logger'

module Capcode
  Resource = Mongoid::Document
  
  class Base
  end
  
  class << self
    def db_connect( dbfile, logfile )
      dbconfig = YAML::load(File.open(dbfile)).keys_to_sym
      
      connection = Mongo::Connection.new(dbconfig[:host], dbconfig[:port])
      Mongoid.database = connection.db(dbconfig[:database])
      if dbconfig[:username]
        Mongoid.database.authenticate(dbconfig[:username], dbconfig[:password])
      end
    end
  end
end
