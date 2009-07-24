require 'rubygems'
require 'couch_foo'
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
