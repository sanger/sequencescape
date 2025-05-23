# frozen_string_literal: true

Rails.application.config.to_prepare do
  unless Rails.env.test?
    BulkSubmissionExcel.configure do |config|
      config.folder = File.join('config', 'bulk_submission_excel')
      config.load!
    end
  end
end
