require 'march_hare'
require 'google/protobuf'



# Generate a repeating message.
#
# This plugin is intented only as an example.

class Test

  def initialize()

    @tls = false
    @verify_peers = false
    @conn = MarchHare.connect(:host=>"localhost",:port=>5004,:verify_peer=>@verify_peer,:tls=>@tls,:user=>"cb",:pass=>"cIuR3TmiBhpBtvvd")
    @channel = @conn.create_channel
    @name="logstash-cber"
    @queue = @channel.queue(@name)
    @queue.bind("api.events",:options=>{:routing_key => ""})
    routing_keys = ['alert.#','binaryinfo.#','binarystore.#','feed.#','ingress.event.childproc','ingress.event.crossprocopen','ingress.event.emetmitigation','ingress.event.filemod','ingress.event.module','ingress.event.moduleload','ingress.event.netconn','ingress.event.procend','ingress.event.process','ingress.event.processblock','ingress.event.procstart','ingress.event.regmod','ingress.event.remotethread','ingress.event.tamper','watchlist.#']

    for rk in routing_keys do
        puts 'trying to queue_bind api.events w/ rk : %s' % [rk]
        @queue.bind("api.events",:routing_key => rk)
    end

    @queue.bind("api.rawsensordata",:options=>{:routing_key => ""})

    @queue.subscribe(:block=>true,:ack=>true) do |metadata, payload|
        puts payload
    end

  end

end

cb = Test.new

