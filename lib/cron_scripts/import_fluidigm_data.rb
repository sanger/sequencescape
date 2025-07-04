# frozen_string_literal: true

module CronScripts
  module ImportFluidigmData
    def self.process
      Plate.requiring_fluidigm_data.find_each(&:retrieve_fluidigm_data)
    rescue StandardError => e
      ExceptionNotifier.notify_exception(e, data: { message: 'Import Fluidigm Data Cron Failed' })
      Rails.logger.error("Import Fluidigm Data Cron Failed: #{e.message}")
    end
  end
end
