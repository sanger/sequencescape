# frozen_string_literal: true

# Run on boot, but do not run again on reload
Rails.application.config.after_initialize do
  unless Rails.env.test?
    BulkSubmissionExcel.configure do |config|
      config.folder = File.join('config', 'bulk_submission_excel')
      config.load!
    end
  end
end
