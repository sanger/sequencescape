# frozen_string_literal: true

FactoryBot.define do
  factory :accession_status_group, class: 'Accession::StatusGroup' do
    submitting_user factory: %i[user]
    accession_group { nil }
    accession_group_type { nil }
  end
end

FactoryBot.define do
  factory :accession_status, class: 'Accession::Status' do
    sample
    status_group factory: %i[accession_status_group]
    status { 'queued' }
    message { nil }
  end
end
