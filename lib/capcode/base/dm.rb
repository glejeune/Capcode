require 'rubygems'
begin
  require 'dm-core'
rescue LoadError => e
  raise Capcode::MissingLibrary, "DataMapper could not be loaded (is it installed?): #{e.message}"
end
require 'yaml'
require 'logger'

module Capcode 
  Resource = DataMapper::Resource

  # use DataMapper
  # 
  # class Story < Capcode::Base
  #   include Capcode::Base
  #   property :id, Integer, :serial => true
  #   property :title, String
  #   property :body, String
  #   property :date, String
  # end  
  class Base
  end
  
  class << self
    def db_connect( dbfile, logfile ) #:nodoc:
      dbconfig = YAML::load(File.open(dbfile)).keys_to_sym
      DataMapper.setup(:default, dbconfig)
      DataMapper::Logger.new(logfile, :debug)
      DataMapper.auto_upgrade!
    end
  end
end