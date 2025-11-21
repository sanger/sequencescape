# frozen_string_literal: true

FactoryBot.define do
  factory :accession_status, class: 'Accession::Status' do
    sample
    status { 'queued' }
    message { nil }
  end
end
