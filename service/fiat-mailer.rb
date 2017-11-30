require 'net/smtp'
require 'date'

class FiatMailer

  def self.send_email(to,opts={},csv)
    opts[:server]      ||= 'smtp.gmail.com'
    opts[:port]        ||= 587
    opts[:domain]      ||= 'gmail.com'
    opts[:username]    ||= 'roger.yuan.fang@gmail.com'
    opts[:password]    ||= '80576755itcfzyy'
    opts[:from]        ||= 'roger.yuan.fang@gmail.com'
    opts[:from_alias]  ||= 'Fiat Mail'
    opts[:subject]     ||= "Error Payments "
    opts[:body]        ||= ''
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

    encodedcontent = [csv].pack("m")   # base64

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
    
    # Define the attachment section
    part3 = <<~EOF
    Content-Type: multipart/mixed; name = \"#{opts[:filename]}\"
    Content-Transfer-Encoding:base64
    Content-Disposition: attachment; filename = "#{opts[:filename]}_#{DateTime.parse(Time.now.to_s).strftime('%Y%m%d_%H:%M_%Z')}.csv"
    
    #{encodedcontent}
    --#{marker}--
    EOF
    
    mailtext = part1 + part2 + part3
  end

end

