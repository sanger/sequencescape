#should be loaded after the configatron load. (so we name it z_...)
ExceptionNotifier.sender_address = %("Projects Exception Notifier" <#{configatron.admin_email}>)
ExceptionNotifier.email_prefix = "[Projects #{Rails.env.upcase}] "
ExceptionNotifier.exception_recipients = %W(#{configatron.exception_recipients})
