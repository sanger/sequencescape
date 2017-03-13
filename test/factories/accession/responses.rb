require File.join(Rails.root, 'spec', 'support', 'mock_accession')

include MockAccession

FactoryGirl.define do
  factory :accession_response, class: Accession::Response do
    response { MockAccession::Response.new(400, '') }

    initialize_with { new(response) }

    factory :successful_accession_response do
      response { successful_accession_response }
    end

    factory :failed_accession_response do
      response { failed_accession_response }
    end

    skip_create
  end
end
