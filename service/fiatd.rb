#!/usr/bin/env ruby
require 'rubygems'
require 'json'
require 'bunny'
require 'logger'

require_relative './fiatd-server'
require_relative './amqp_queue'
require_relative '../util/fiatd_logger'

#
# === an interface of application and Fiat Server
#
# get request from AMQP and pass it to Fiat Server
# get response from Fiat Server and pass it to AMQP
#
class RemainAlmostDoneError < RuntimeError; end

class Fiatd
  attr_accessor :logger, :busy

  #
  #==== Initalize the class
  #
  # read and parse Fiat.yml on the same directory
  # initialize AMQP connection setting
  #
  def initialize fiat_config
    @fiat_config = fiat_config
    @logger = FiatdLogger.new(@fiat_config[:fiat][:log_level])
    @fiat_server = FiatdServer.new(@logger)
    @conn = Bunny.new(@fiat_config[:rabbitmq]).tap {|conn| conn.start}
    @ch = @conn.create_channel
    @ch.prefetch(1)
    @busy = false
  end

  #
  #==== Start service
  #
  # start to subscribe AMPQ queue and response
  #
  # request:
  #   payload:
  #     {:command => command,
  #      :params => [<param1>, <param2>, ......…],
  #      :created_at => <timestamp> }
  #
  # response:
  #   hash
  #   different by command,
  #   but always include command and created_at
  #
  # for future onboard more currencies
  # set @server to different fiat-server
  # e.g. @server = Server.new(tokens["payment_type"])
  def start
    #raise RemainAlmostDoneError if remain_doing?
    queue = @ch.queue(@fiat_config[:queue][:request][:name], :durable => true)
    # when block is true the consumer thread join main thread
    queue.subscribe(:block => true, :manual_ack=> true) do |delivery, _, payload|
      begin
        @busy = !@busy
        @logger.debug "request: #{payload}"
        tokens = JSON::parse(payload)

        raise Exception unless tokens["payment_type"]

        @server = @fiat_server.send(tokens["payment_type"].downcase)

        response = {
          command: tokens["command"],
          created_at: tokens["created_at"],
          currency: tokens["currency"]
        }

        command = method_name(tokens["command"])
        raise InvalidCommand unless self.class.private_method_defined?(command)
        params  = tokens["params"]

        response.merge!(self.__send__(command, params))
        @logger.debug "#{response}"
        if response[:log]
          @logger.info "*** MQ execute result: #{response} ***"
        else 
          AMQPQueue.enqueue(response) 
        end
        @ch.ack(delivery.delivery_tag)

      rescue FiatServiceError => e
        response[:error_code] = e.code
        response[:error_message] = e.inspect
        response[:params] = params
        @logger.error "response : #{response} debug_info: #{e.backtrace[0..2]}"
        AMQPQueue.enqueue(response)
        @ch.ack(delivery.delivery_tag)
      rescue ActiveRecord::RecordNotFound => e
        @logger.debug "response : #{e.inspect}"
        @ch.ack(delivery.delivery_tag)
      rescue Exception => e
        @logger.error "Unhandle Error"
        @logger.error ErrorHandler.error_info(e)
        #@ch.ack(delivery.delivery_tag)
        exit(3)
      ensure
        if @busy
          @busy = !@busy
        else
          delivery.consumer.cancel
          @logger.info "Cancelling #{delivery.consumer.consumer_tag}"
        end
      end
    end
  end


  def shutdown
    @ch.work_pool.shutdown
  end

  #
  #==== Stop service
  #
  # Stop the AMPQ connection
  #
  def stop
    @ch.close
    @conn.close
  end

  private

  #
  #==== Convert a command to method name
  #
  #  command : string
  #  return  : string
  #
  #  to prevent from conflict of method name
  #  example:  getbalance ->  cmd_getbalance
  #
  def method_name(command)
    "cmd_#{ command.downcase }"
  end

  #
  #==== Get Customer Deposit Code for account_id and currency name
  #
  # params : hash
  #  {
  #    :account_id => <account_id> : integer  - account id of the member
  #    :currency => <currency_name> : string   - currency name of fiat
  #  }
  #
  # return : hash
  #  {
  #    :isvalid => true - always true,
  #    :customer_code => <customer_code> : string - unique customer_code,
  #    :ismine  => true - always true,
  #    :account_id => <account_id> - from params
  #  }
  #
  def cmd_getcustomercode(params)
    raise InvalidArgumentError unless params.has_key?("currency") and params.has_key?("account_id")
    raise InvalidArgumentError unless params["currency"].is_a? String
    raise InvalidArgumentError unless params["account_id"].is_a? Integer
    {
      :isvalid => true,
      :customer_code => @server.getcustomercode(params["account_id"]),
      :ismine  => true,
      :account_id => params["account_id"]
    }
  end

  #
  #==== Validate Customer Deposit Code for currency
  #
  # params : hash
  #  {
  #    :customer_code => <customer_code> : string   - unique customer code for deposit
  #    :account_id => <account_id>       : integer  - account id of the member
  #    :currency => <currency>           : string   - currency name
  #  }
  #
  # return : hash
  #  {
  #    :isvalid => <isvalid> : boolean,
  #    :customer_code => <customer_code> - from params,
  #    :ismine  => <ismine> : boolean,
  #    :account_id => <account_id> - from params
  #  }
  #
  def cmd_validatecustomercode(params)
    raise InvalidArgumentError unless params.has_key?("customer_code") and params.has_key?("account_id") and params.has_key?("currency")
    raise InvalidArgumentError unless params["customer_code"].is_a? String && params["customer_code"].size == 16
    raise InvalidArgumentError unless params["account_id"].is_a? Integer
    raise InvalidArgumentError unless params["currency"].is_a? String
    server_response = @server.validatecustomercode(params["customer_code"], params["account_id"])
    {
      :isvalid => server_response[:isvalid],
      :customer_code => params["customer_code"],
      :ismine  => server_response[:ismine],
      :account_id => params["account_id"]
    }
  end

  #
  # ==== deposit
  #
  # params: hash
  # {
  #   payment_id : Integer
  #   deposit    : Hash
  # }
  #
  # return: boolean - deposit mapping payment successfully or not
  #
  #
  def cmd_autodeposit params
    @server.autodeposit(params)
  end

  #
  #==== Synchronize bank accounts with ACX
  #
  # params : hash
  #  {
  #    "<currency>"=>[bank_accounts] : string   - currency name of fiat
  #    bank_accounts                 : hash     - currency's bank accounts
  #  }
  #
  # return : nil
  #
  def cmd_refreshbankaccounts(params)
    @server.refreshbankaccounts(params)
  end

end