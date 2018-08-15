require 'exception_notification'

begin
  PlateVolume.process_all_volume_check_files
rescue StandardError => exception
  ExceptionNotifier.notify_exception(exception,
    :data => { :message => 'Process Volume Check Files Cron Failed' })
  $stderr.puts exception.to_s
end
