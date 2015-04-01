require 'bunny'

module Acapi
  class Requestor
    class DoNothingRequestor
      def request(*args)
        nil
      end

      def reconnect!
      end

      def disconnect!
      end

    end

    class AmqpRequestor
      def initialize(app_id, uri, conn)
        @app_id = app_id
        @uri = uri
        @connection = conn
      end

      def request(req_name, payload,timeout=1)
        requestor = ::Acapi::Amqp::Requestor.new(@connection)
        req_time = Time.now
        msg = ::Acapi::Amqp::OutMessage.new(@app_id, req_name, req_time, req_time, nil, payload)
        requestor.request(*msg.to_request_properties(timeout))
#        in_msg = ::Acapi::Amqp::InMessage.new(*requestor.request(*msg.to_request_properties))
#        in_msg.to_response
      end

      def reconnect!
        disconnect!
        @connection = Bunny.new(@uri)
        @connection.start
      end

      def disconnect!
        @connection.close
      end
    end

    def self.disable!
      if defined?(@@instance) && !@instance.nil?
        @@instance.disconnect!
      end
      @@instance = DoNothingRequestor.new
    end

    def self.boot!(app_id, uri)
      if defined?(@@instance) && !@instance.nil?
        @@instance.disconnect!
      end
      conn = Bunny.new(uri)
      conn.start
      @@instance = AmqpRequestor.new(app_id, uri, conn)
    end

    def self.request(req_name, payload, timeout=1)
      @@instance.request(req_name, payload,timeout)
    end
  end
end
