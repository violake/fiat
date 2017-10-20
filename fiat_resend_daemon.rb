#!/usr/bin/env ruby
require_relative './config/environment'
require_relative './config/fiat_config.rb'
require_relative './service/fiatd-resender'

fiatd_resender = FiatdResender.new(FiatConfig.new)

logger = fiatd_resender.logger

terminate = proc do
  puts "Terminating threads .."
  fiatd_resender.shutdown
  puts "Stop"
end

clean_terminate = proc do
  if fiatd_resender.busy
    fiatd_resender.busy = !fiatd_resender.busy
  else
    puts "Not busy"
    terminate.call
  end
end

Signal.trap("TERM",  &clean_terminate)
Signal.trap("INT", &terminate)

logger.info("FiatdResender daemon start !")
begin
  fiatd_resender.resend
rescue RemainAlmostDoneError => e
  logger.error("Please finish pending transaction before starting service")
  exit(1)
end