require 'exception_notification'

begin
  Plate.requiring_fluidigm_data.find_each do |plate|
    plate.retrieve_fluidigm_data
  end
rescue StandardError => e
  ExceptionNotifier.notify_exception(e,
                                     :data => { :message => 'Import Fluidigm Data Cron Failed' })
  $stderr.puts e.to_s
end
