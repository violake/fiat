require "bunny"
require "hashie"
require_relative "../config/fiat_config"

class AMQPQueue
  class<<self
    def config
      @config ||= FiatConfig.new
    end

    def connection
      @connection ||= Bunny.new(config[:rabbitmq]).tap {|conn| conn.start}
    end

    def channel
      @channel ||= connection.create_channel
    end

    def queue
      @queue ||= channel.queue(@config[:queue][:response][:name], :durable => true)
    end

    def subscribe_queue
      @sub_queue ||= channel.queue(@config[:queue][:request][:name], :durable => true)
    end

    def enqueue payload, attrs={}, queue_name=queue.name
      payload_json = payload.to_json
      attrs.merge!({routing_key: queue_name})
      attrs.merge!({persistent: true})
      channel.default_exchange.publish(payload_json, attrs)
    end
  end
end