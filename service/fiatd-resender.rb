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

class FiatdResender
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
    @busy = false
    @resending = true
  end

  def bank_cron
    @fiat_config[:fiat][:fund_refresh_cron]
  end

  def frequence
    @fiat_config[:fiat][:resend_frequence]
  end

  def sync_bank_accounts
    hash = YAML.load_file("./config/fund_source.yml")
    if !hash["fund_timestamp"] || Time.now - hash["fund_timestamp"] > 1.days
      @fiat_server.bank.sync_bank_accounts
    end
  end

  #
  #==== resending payments that haven't got reply messages
  # 
  def resend
    if @resending && !@busy
      begin
        @busy = !@busy
        @fiat_config[:fiat][:payment_type].each do |fiat|
          @resend_server ||= @fiat_server.send(fiat)
          count = @resend_server.resend
          @logger.info "*** #{fiat} resend #{count} payments ***"
        end
        @busy_count = 0
      rescue Exception => e
        puts e.message
      ensure
        @busy = !@busy if @busy
      end
    elsif @resending && @busy
      @busy_count ||= 0
      @logger.info "*** #Last resending job is still processing ***"
      @busy_count += 1
      $logger.error "[Fiat Resend] job processing for too long time: over '#{@busy_count}' times" if @busy_count > 10
    end
  end

  def shutdown
    pause_resend
    @ch.work_pool.shutdown
  end

  #
  #==== pause resending
  # 
  def pause_resend
    @resending = false
  end

  #
  #==== resume resending
  #
  def resume_resend
    @resending = true
  end

end