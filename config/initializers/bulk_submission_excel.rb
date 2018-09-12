# frozen_string_literal: true

unless Rails.env.test?
  BulkSubmissionExcel.configure do |config|
    config.folder = File.join('config', 'bulk_submission_excel')
    config.load!
  end
end
