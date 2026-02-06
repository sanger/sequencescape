# frozen_string_literal: true

FactoryBot.define do
  factory :accession_submission, class: 'Accession::Submission' do
    sample { build(:accession_sample) }

    initialize_with { new(sample) }
    skip_create
  end
end
