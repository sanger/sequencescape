# frozen_string_literal: true

FactoryBot.define do
  factory :aker_job, class: 'Aker::Job' do
    sequence(:aker_job_id) { |n| n }

    aker_job_url { 'someurl' }

    job_uuid { SecureRandom.uuid }

    factory :aker_job_with_samples do
      samples { create_list(:sample_for_job, 5) }
    end
  end
end
