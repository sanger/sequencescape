# frozen_string_literal: true

FactoryBot.define do
  factory :accession_sample_status, class: 'Accession::SampleStatus' do
    sample
    status { 'queued' }
    message { nil }
  end
end
