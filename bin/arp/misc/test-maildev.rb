require 'net/smtp'

message = <<~EMAIL
From: test@example.com
To: recipient@example.com
Subject: Test Email to MailDev

This is a test email sent to MailDev. If you're seeing this, it worked!
EMAIL

begin
  Net::SMTP.start('localhost', 1025) do |smtp|
    smtp.send_message(
      message,
      'test@example.com',
      'recipient@example.com'
    )
  end
  puts "Test email sent successfully!"
rescue => e
  puts "Error sending email: #{e.message}"
end
