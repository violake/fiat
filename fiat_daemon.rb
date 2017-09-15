#!/usr/bin/env ruby
require_relative './config/fiat_config.rb'
require_relative './service/fiatd'

fiatd = Fiatd.new(FiatConfig.new)

logger = fiatd.logger

terminate = proc do
  puts "Terminating threads .."
  fiatd.shutdown
  puts "Stop"
end

clean_terminate = proc do
  if fiatd.busy
    fiatd.busy = !fiatd.busy
  else
    puts "Not busy"
    terminate.call
  end
end

Signal.trap("TERM",  &clean_terminate)
Signal.trap("INT", &terminate)

logger.info("Fiat daemon start !")
begin
  fiatd.start
rescue RemainAlmostDoneError => e
  logger.error("Please finish pending transaction before starting service")
  exit(1)
end