require 'bunny'
require 'json'
require 'thread'

module BunnyBurrow
  STATUS_OK = 'ok'
  STATUS_CLIENT_ERROR = 'client_error'
  STATUS_SERVER_ERROR = 'server_error'

  class Base
    attr_accessor(
      :rabbitmq_url,
      :rabbitmq_exchange,
      :rabbitmq_connection,
      :logger,
      :log_prefix,
      :verify_peer,
      :timeout,
      :log_request,
      :log_response
    )

    alias_method :verify_peer?, :verify_peer
    alias_method :log_request?, :log_request
    alias_method :log_response?, :log_response

    def initialize
      @log_request = false
      @log_response = false
      @timeout = 60
      @verify_peer = true
      @own_connection = true

      yield self if block_given?

      @connection = @rabbitmq_connection
      @own_connection = @connection.nil?
    end

    def shutdown
      return if @shutdown
      log 'Shutting down'
      channel.close
      connection.close if @own_connection
      @shutdown = true
    end

    private

    def connection
      unless @connection
        @connection = Bunny.new(rabbitmq_url, verify_peer: @verify_peer)
        @connection.start
      end

      @connection
    end

    def channel
      @channel ||= connection.create_channel
    end

    def default_exchange
      @default_exchange ||= channel.default_exchange
    end

    def topic_exchange
      @topic_exchange ||= channel.topic(rabbitmq_exchange, durable: true)
    end

    def lock
      @lock ||= Mutex.new
    end

    def condition
      @condition ||= ConditionVariable.new
    end

    def log(message, level: :info)
      return unless logger
      prefix = log_prefix || 'BunnyBurrow'
      message = "#{prefix}: #{message}"
      logger.send(level, message)
    end
  end
end

