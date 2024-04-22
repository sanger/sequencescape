# frozen_string_literal: true
require 'exception_notification'

begin
  Plate.requiring_fluidigm_data.find_each(&:retrieve_fluidigm_data)
rescue StandardError => e
  ExceptionNotifier.notify_exception(e, data: { message: 'Import Fluidigm Data Cron Failed' })
  warn e
end
