# frozen_string_literal: true

Rails.application.config.to_prepare do
  unless Rails.env.test?
    BulkSubmissionExcel.configure do |config|
      config.folder = File.join('config', 'bulk_submission_excel')
      config.load!
    rescue StandardError => e
      # catch undefined local variable or method `list_model' for an instance of
      # SequencescapeExcel::ConditionalFormattingDefaultList
      Rails.logger.warn("Error loading bulk submission excel configuration: #{e.message}")
    end
  end
end
