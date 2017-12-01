#!/usr/bin/env ruby
require_relative './config/environment'
require_relative './config/fiat_config.rb'
require_relative './service/fiatd'
require_relative './service/fiat-mailer'

begin
  fiatd = Fiatd.new(FiatConfig.new)
  logger = fiatd.logger
  logger.info("Fiat daemon start !")
  fiatd.start
rescue Bunny::TCPConnectionFailed => e
  msg = "Connect to RabbitMQ failed.\nPlease check MQ server address."
  puts msg
  opts={subject: "ALERT: Fiat MQ",
        body: "Fiat Error: #{msg}"}
  FiatMailer.send_email(FiatConfig.new[:fiat_email][:admin_email], opts)
rescue SignalException =>e
  puts "Terminating process .."
  fiatd.shutdown
  puts "Stopped."
end