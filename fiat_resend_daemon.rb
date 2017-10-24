#!/usr/bin/env ruby
require 'rufus/scheduler'
require_relative './config/environment'
require_relative './config/fiat_config.rb'
require_relative './service/fiatd-resender'

scheduler = Rufus::Scheduler.new

terminate = proc do
  puts "Polling Terminated"
  fiatd_resender.shutdown
  scheduler.shutdown(:wait)
  puts "Stop"
end
Signal.trap("TERM", &terminate)
Signal.trap("INT", &terminate)

fiatd_resender = FiatdResender.new(FiatConfig.new)

$logger = fiatd_resender.logger

$logger.info("FiatdResender daemon start !")
scheduler.every "#{fiatd_resender.frequence}m", first: :now do
  begin
    $logger.debug("FiatdResender resend start !")
    fiatd_resender.resend
  rescue => e
    $logger.error ErrorHandler.error_info(e)
  end
end

scheduler.every "1d", first: :now do
  begin
    $logger.debug("FiatdResender sync bank accounts start !")
    fiatd_resender.sync_bank_accounts
  rescue => e
    $logger.error ErrorHandler.error_info(e)
  end
end

scheduler.join