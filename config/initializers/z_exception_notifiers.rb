#should be loaded after the configatron load. (so we name it z_...)
ExceptionNotification::Notifier.sender_address = %("Projects Exception Notifier" <#{configatron.admin_email}>)
ExceptionNotification::Notifier.email_prefix = "[Projects #{Rails.env.upcase}] "
ExceptionNotification::Notifier.exception_recipients = %W(#{configatron.exception_recipients})
