module Capcode
  # This module contains the resources needed in a model
  module Resource
  end
  
  # This class allow you to define models
  # 
  #   class Story < Capcode::Base
  #     include Capcode::Resource
  #
  #     property :id, Integer, :serial => true
  #     property :title, String
  #     property :body, String
  #     property :date, String
  #   end
  #
  # If you want to use DataMapper, you need to require "capcode/base/dm", if
  # you want to use CouchDB (via couch_foo), you need to require "capcode/base/couchdb".
  # 
  # Please, refer to the DataMapper or couch_foo documentation for more information.
  class Base
  end
end