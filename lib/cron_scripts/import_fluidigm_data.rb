require 'exception_notification'

begin
  Plate.requiring_fluidigm_data.find_each do |plate|
    plate.retrieve_fluidigm_data
  end
rescue StandardError => exception
  ExceptionNotifier.notify_exception(exception,
    :data => { :message => 'Import Fluidigm Data Cron Failed' })
  $stderr.puts exception.to_s
end
