# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "stud/interval"
require "socket" # for Socket.gethostname
require 'march_hare'
require './protobuf-java-3.3.1.jar'
require './target/SensorEvents.jar'
require './protobuf-java-util-3.3.1.jar'
require './gson-2.8.1.jar'
require './guava-23.0.jar'
require 'java'
require 'json'
java_import "com.carbonblack.SensorEvents.SensorEventsProtos"
java_import "com.google.protobuf.util.JsonFormat"

class LogStash::Inputs::Cber < LogStash::Inputs::Base
  config_name "cber"

  # If undefined, Logstash will complain, even if codec is unused.
  default :codec, "plain"

  config :rabbitmquser , :validate => :string, :default => "cb"
  config :rabbitmqpassword , :validate => :string, :default => "PASSWORD"
  config :rabbitmqport , :validate => :number , :default => 5004
  config :rabbitmqhost , :validate => :string , :default => "localhost"

  public
  def register
    typeregistrybuilder = JsonFormat::TypeRegistry.newBuilder()
    cbeventmsg = SensorEventsProtos::CbEventMsg
    @typeregistry = typeregistrybuilder.add(cbeventmsg.getDescriptor()).build()
    @jsonprinter = JsonFormat.printer().usingTypeRegistry(@typeregistry)
    @tls = false
    @verify_peers = false
    @host = Socket.gethostname
    @conn = MarchHare.connect(:host=>@rabbitmqhost,:port=>@rabbitmqport,:verify_peer=>@verify_peer,:tls=>@tls,:user=>@rabbitmquser,:pass=>@rabbitmqpassword)
    @channel = @conn.create_channel
    @name="logstash-cber"
    @queue = @channel.queue(@name)
    @queue.bind("api.events",:options=>{:routing_key => ""})
    @routing_keys = ['alert.#','binaryinfo.#','binarystore.#','feed.#','ingress.event.childproc','ingress.event.crossprocopen','ingress.event.emetmitigation','ingress.event.filemod','ingress.event.module','ingress.event.moduleload','ingress.event.netconn','ingress.event.procend','ingress.event.process','ingress.event.processblock','ingress.event.procstart','ingress.event.regmod','ingress.event.remotethread','ingress.event.tamper','watchlist.#']
    for rk in @routing_keys do
        puts 'trying to queue_bind api.events w/ rk : %s' % [rk]
        @queue.bind("api.events",:routing_key => rk)
    end
    puts 'trying to queue_bind api.rawsensordata'
    @queue.bind("api.rawsensordata",:routing_key => "")
    puts "done registering"

  end # def register

  def run(queue)
    @queue.subscribe(:block=>true,:ack=>true) do |metadata, payload|
        if  @routing_keys.include? metadata.routing_key and  not metadata.routing_key.nil?
            puts 'metadata.routing_key = %s' % [metadata.routing_key]
            routing_key = metadata.routing_key
            cbeventmsg = SensorEventsProtos::CbEventMsg.parseFrom(payload.to_java_bytes)
            json_str = @jsonprinter.print(cbeventmsg)
            json_msg = JSON.parse(json_str)
            event = LogStash::Event.new(:message => json_msg ,"host"=>@host , :routing_key => routing_key)
        else
            event = LogStash::Event.new(:message => payload ,"host"=>@host,:routing_key=>nil)
        end
        decorate(event)
        queue << event
    end

  end # def run

  def stop
    # nothing to do in this case so it is not necessary to define stop
    # examples of common "stop" tasks:
    #  * close sockets (unblocking blocking reads/accepts)
    #  * cleanup temporary files
    #  * terminate spawned threads
  end

end # class LogStash::Inputs::Cber