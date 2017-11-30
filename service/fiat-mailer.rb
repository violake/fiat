require 'net/smtp'
require 'date'
require_relative './config/fiat_config'

class FiatMailer

  def self.send_email(to,opts={},csv=nil)
    @@fiat_config = FiatConfig.new
    opts[:server]      ||= @fiat_config[:fiat_email][:server]
    opts[:port]        ||= @fiat_config[:fiat_email][:port]
    opts[:domain]      ||= @fiat_config[:fiat_email][:domain]
    opts[:username]    ||= @fiat_config[:fiat_email][:username]
    opts[:password]    ||= @fiat_config[:fiat_email][:password]
    opts[:from]        ||= @fiat_config[:fiat_email][:from]
    opts[:from_alias]  ||= @fiat_config[:fiat_email][:from_alias]
    opts[:subject]     ||= @fiat_config[:fiat_email][:subject]
    opts[:body]        ||= @fiat_config[:fiat_email][:body]
    opts[:filename]    ||= 'errorpayments'
    opts[:to]            = to

    msg = self.make_content(csv, opts)

    puts "start sending"

    smtp = Net::SMTP.new opts[:server], opts[:port]
    smtp.enable_starttls if opts[:starttls]
    smtp.start(opts[:domain], opts[:username], opts[:password], :login) do
      smtp.send_message msg, opts[:from], to
      puts "email has been sent to #{to}"
    end
  rescue Exception=>e
    print "Exception occured: " + e.message
    puts e.backtrace.inspect
  end

  def self.make_content(csv, opts)

    encodedcontent = [csv].pack("m") if csv  # base64

    marker = "Fiat"

    body = opts[:body].dup

    puts body

    # Define the main headers.
    part1 = <<~EOF
    From: #{opts[:from_alias]} <#{opts[:from]}>
    To: <#{opts[:to]}>
    Subject: #{opts[:subject]}
    MIME-Version: 1.0
    Content-Type: multipart/mixed; boundary = #{marker}
    --#{marker}
    EOF
    
    # Define the message action
    part2 = <<~EOF
    Content-Type: text/plain
    Content-Transfer-Encoding:8bit
    
    #{body.gsub!('\n', "\n")}
    --#{marker}
    EOF
    
    mailtext = part1 + part2

    if csv
      # Define the attachment section
      part3 = <<~EOF
      Content-Type: multipart/mixed; name = \"#{opts[:filename]}\"
      Content-Transfer-Encoding:base64
      Content-Disposition: attachment; filename = "#{opts[:filename]}_#{DateTime.parse(Time.now.to_s).strftime('%Y%m%d_%H:%M_%Z')}.csv"
      
      #{encodedcontent}
      --#{marker}--
      EOF

      mailtext += part3
    end
    
    mailtext 
  end

end

