#!/usr/bin/env ruby
require_relative './config/environment'
require_relative './config/fiat_config.rb'
require_relative './service/fiatd'
require_relative './service/fiat-mailer'

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
rescue Bunny::TCPConnectionFailed => e
  msg = "Connect to RabbitMQ failed. Please check MQ server address."
  logger.error(msg)
  opts={subject: "ALERT: Fiat MQ",
        body: "Fiat Error: #{msg}"}
  FiatMailer.send_email(FiatConfig.new[:fiat_email][:admin_email], opts)
  exit(1)
end