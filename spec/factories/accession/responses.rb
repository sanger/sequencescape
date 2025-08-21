# frozen_string_literal: true

require Rails.root.join('spec/support/mock_accession')

FactoryBot.define do
  factory :accession_response, class: 'Accession::Response' do
    response { MockAccession::Response.new(400, '') }

    initialize_with { new(response) }

    factory :successful_sample_accession_response do
      response { MockAccession.successful_sample_accession_response }
    end

    factory :failed_accession_response do
      response { MockAccession.failed_accession_response }
    end

    skip_create
  end
end
