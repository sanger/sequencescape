# frozen_string_literal: true

FactoryBot.define do
  factory :sample_for_job, class: 'Sample' do
    sequence(:name) { |n| "2be2072d-7c96-49c3-b7ac-9c51d01c109#{n}" }
    container { create :container_with_address }
    sample_metadata { Sample::Metadata.new(gender: 'male', donor_id: 'd', phenotype: 'p', sample_common_name: 'Mouse') }
  end
end
