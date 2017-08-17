require 'march_hare'
require 'java'
require 'json'
require './target/SensorEvents.jar'
require './protobuf-java-3.3.1.jar'
require './protobuf-java-util-3.3.1.jar'
require './gson-2.8.1.jar'
require './guava-23.0.jar'
java_import "com.google.protobuf.util.JsonFormat"
java_import "com.carbonblack.SensorEvents.SensorEventsProtos"
# Generate a repeating message.
#
# This plugin is intented only as an example.


def update_recursive(hash,matcher,updater)
  hash.each do |k, v|
    #puts 'update recursive: k,v = %s,%s before update' % [k,v]
    if matcher.call(k,v)
      v.replace updater.call(k,v)
      puts 'update recursive: k,v = %s,%s after update ' % [k,v]
    elsif v.is_a?(Hash)
      update_recursive(v,matcher,updater)
    elsif v.is_a?(Array)
      v.flatten.each { |x| update_recursive(x,matcher,updater) if x.is_a?(Hash) }
    end
  end
  hash
end

class Test

  def initialize()
    typeregistrybuilder = JsonFormat::TypeRegistry.newBuilder()
    cbeventmsg = SensorEventsProtos::CbEventMsg
    @typeregistry = typeregistrybuilder.add(cbeventmsg.getDescriptor()).build()
    @jsonprinter = JsonFormat.printer().usingTypeRegistry(@typeregistry)
    @tls = false
    @verify_peers = false
    @conn = MarchHare.connect(:host=>"localhost",:port=>5004,:verify_peer=>@verify_peer,:tls=>@tls,:user=>"cb",:pass=>"cIuR3TmiBhpBtvvd")
    @channel = @conn.create_channel
    @name="logstash-cber"
    @queue = @channel.queue(@name)
    @queue.bind("api.events",:options=>{:routing_key => ""})
    @routing_keys = ['alert.#','binaryinfo.#','binarystore.#','feed.#','ingress.event.childproc','ingress.event.crossprocopen','ingress.event.emetmitigation','ingress.event.filemod','ingress.event.module','ingress.event.moduleload','ingress.event.netconn','ingress.event.procend','ingress.event.process','ingress.event.processblock','ingress.event.procstart','ingress.event.regmod','ingress.event.remotethread','ingress.event.tamper','watchlist.#']

    for rk in @routing_keys do
        puts 'trying to queue_bind api.events w/ rk : %s' % [rk]
        @queue.bind("api.events",:routing_key => rk)
    end

    #@queue.bind("api.rawsensordata",:options=>{:routing_key => ""})
    puts "Entering Subscribe"
    @queue.subscribe(:block=>true,:ack=>true) do |metadata, payload|
        puts "payload = %s , metadata = %s" % [payload.to_s, metadata.inspect]
        if  @routing_keys.include? metadata.routing_key
            cbeventmsg = SensorEventsProtos::CbEventMsg.parseFrom(payload.to_java_bytes)
            json_str = @jsonprinter.print(cbeventmsg)
            puts json_str
            json_msg = JSON.parse(json_str)
            #update_recursive(json_msg, matcher,updater)
            puts json_msg
        else
            puts payload
        end
    end

  end

end

cb = Test.new

