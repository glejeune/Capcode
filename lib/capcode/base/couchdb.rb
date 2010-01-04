require 'rubygems'
begin
  require 'couch_foo'
rescue LoadError => e
  raise Capcode::MissingLibrary, "CouchFoo could not be loaded (is it installed?): #{e.message}"
end
require 'yaml'
require 'logger'

module Capcode
  module Resource
  end
  
  Base = CouchFoo::Base
  
  class << self
    def db_connect( dbfile, logfile )
      dbconfig = YAML::load(File.open(dbfile)).keys_to_sym
      Base.set_database(dbconfig)
      Base.logger = Logger.new(logfile)
    end
  end
end
