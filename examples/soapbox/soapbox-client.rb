# (The MIT License)
# 
# Copyright (c) 2009 Grégoire Lejeune
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# 'Software'), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'net/http'
require 'uri'
require 'rubygems'
require 'json'
require 'faye'

module Faye
  class Client    
    def initialize( uri_or_string )
      @uri = uri_or_string
      @uri = URI.parse(@uri) if @uri.class == String
      @clientId = nil
      @interval = nil
      @connection = nil
      @subscriptions = {}
    end
    
    # Request                              Response
    # MUST include:  * channel             MUST include:  * channel
    #                * clientId                           * successful
    #                * connectionType                     * clientId
    # MAY include:   * ext                 MAY include:   * error
    #                * id                                 * advice
    #                                                     * ext
    #                                                     * id
    #                                                     * timestamp
    def connect
      @connection.kill unless @connection.nil?
      @connection = Thread.new {
        faild = false
        while true
          id = Faye.random(32)
          message = {
            "channel" => Faye::Channel::CONNECT,
            "clientId" => @clientId,
            "connectionType" => "long-polling",
            "id" => id
          }
          r = send( message )
            
          if r[0]["id"] == id and r[0]["successful"] == true
            @subscriptions[r[1]["channel"]].call( r[1]["data"])
          elsif r[0]["successful"] == false
            faild = true
            break
          end
        end
        
        if faild
          handshake()
          connect()
        end
      }
    end
    
    # Request                              Response
    # MUST include:  * channel             MUST include:  * channel
    #                * clientId                           * successful
    # MAY include:   * ext                                * clientId
    #                * id                  MAY include:   * error
    #                                                     * ext
    #                                                     * id
    def disconnect
      unless @connection.nil?
        @connection.kill 
        message = {
          "channel" => Faye::Channel::DISCONNECT,
          "clientId" => @clientId,
          "id" => Faye.random(32)
        }
        r = send( message )
        ## TODO : Check response
      end
    end
    
    # Request
    # MUST include:  * channel
    #                * version
    #                * supportedConnectionTypes
    # MAY include:   * minimumVersion
    #                * ext
    #                * id
    # 
    # Success Response                             Failed Response
    # MUST include:  * channel                     MUST include:  * channel
    #                * version                                    * successful
    #                * supportedConnectionTypes                   * error
    #                * clientId                    MAY include:   * supportedConnectionTypes
    #                * successful                                 * advice
    # MAY include:   * minimumVersion                             * version
    #                * advice                                     * minimumVersion
    #                * ext                                        * ext
    #                * id                                         * id
    #                * authSuccessful
    def handshake
      id = Faye.random(32)
      message = {
        "channel" => Faye::Channel::HANDSHAKE,
        "version" => Faye::BAYEUX_VERSION,
        "supportedConnectionTypes" => [ "long-polling", "callback-polling" ],
        "id" => id
      }
      
      response = send( message )[0]
      if response["successful"] and response["id"] == id
        @clientId = response["clientId"]
        @interval = response["advice"]["interval"]
      else
        raise
      end
    end
    
    # Request                              Response
    # MUST include:  * channel             MUST include:  * channel
    #                * data                               * successful
    # MAY include:   * clientId            MAY include:   * id
    #                * id                                 * error
    #                * ext                                * ext
    def publish( channel, data )
      message = [
        {
          "channel" => channel,
          "data" => data, 
          "clientId" => @clientId,
          "id" => Faye.random(32)
        }
      ]
      r = send(message)[0]
      ## TODO : Check response
    end
    
    # Request                              Response
    # MUST include:  * channel             MUST include:  * channel
    #                * clientId                           * successful
    #                * subscription                       * clientId
    # MAY include:   * ext                                * subscription
    #                * id                  MAY include:   * error
    #                                                     * advice
    #                                                     * ext
    #                                                     * id
    #                                                     * timestamp
    def subscribe( channels, &block )
      channels = [channels] unless channels.class == Array
      if block
        channels.each do |c|
          @subscriptions[c] = block
        end
      end
      message = {
        "channel" => Faye::Channel::SUBSCRIBE,
        "clientId" => @clientId,
        "subscription" => channels,
        "id" => Faye.random(32)
      }
      
      r = send(message)
      ## TODO : Check response
    end
    
    # Request                              Response
    # MUST include:  * channel             MUST include:  * channel
    #                * clientId                           * successful
    #                * subscription                       * clientId
    # MAY include:   * ext                                * subscription
    #                * id                  MAY include:   * error
    #                                                     * advice
    #                                                     * ext
    #                                                     * id
    #                                                     * timestamp
    def unsubscribe( channels )
      channels = [channels] unless channels.class == Array
      channels.each do |c|
        @subscriptions.delete(c)
      end
      message = {
        "channel" => Faye::Channel::UNSUBSCRIBE,
        "clientId" => @clientId,
        "subscription" => channels,
        "id" => Faye.random(32)
      }
      
      r = send(message)
      ## TODO : Check response
    end
    
    private
    def send( message )
      res = Net::HTTP.post_form( @uri, { "message" => message.to_json } )
      return JSON.parse( res.body )
    end
    
  end
end

if $0 == __FILE__
x = Faye::Client.new( 'http://localhost:3000/comet' )

puts "-- handshake"
x.handshake

puts "-- subscriptions"
x.subscribe( "/mentioning/daemon" )

x.subscribe( "/from/greg" ) { |r|
  puts "#{r["user"]} : #{r["message"]}"
}

puts "-- connect"
x.connect

msg = ""  
while msg != "quit"
  msg = $stdin.readline.chomp
  unless msg == "quit"
    channel = "/from/daemon"
    data = { "user" => "daemon", "message" => msg }
    r = x.publish( channel, data )
    unless r["successful"]
      puts "=> Message not send !"
    end
  end
end

x.disconnect
end
