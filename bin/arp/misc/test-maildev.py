import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# Email configuration
smtp_server = "localhost"
smtp_port = 1025
sender_email = "test@example.com"
receiver_email = "recipient@example.com"

# Create message
message = MIMEMultipart()
message["From"] = sender_email
message["To"] = receiver_email
message["Subject"] = "Test Email to MailDev"

# Add body
body = "This is a test email sent to MailDev. If you're seeing this, it worked!"
message.attach(MIMEText(body, "plain"))

# Send email
try:
    with smtplib.SMTP(smtp_server, smtp_port) as server:
        server.send_message(message)
    print("Test email sent successfully!")
except Exception as e:
    print(f"Error sending email: {e}")
