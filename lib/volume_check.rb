# frozen_string_literal: true

module VolumeCheck
  def self.process
    PlateVolume.process_all_volume_check_files
  rescue StandardError => e
    ExceptionNotifier.notify_exception(e, data: { message: 'Process Volume Check Files Cron Failed' })
    $stderr.puts e.to_s
  end
end
