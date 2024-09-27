# frozen_string_literal: true

FactoryBot.define do
  factory :db_file do
    data { 'blahblahblah' }
  end

  factory :study_report do
    study

    factory :pending_study_report

    factory :completed_study_report do
      report_filename { 'progress_report.csv' }
      after(:build) do |study_report_file|
        create(:db_file, owner: study_report_file, data: Tempfile.open('progress_report.csv').read)
      end
    end
  end
end
