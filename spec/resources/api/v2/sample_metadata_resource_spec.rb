# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/sample_metadata_resource'

RSpec.describe Api::V2::SampleMetadataResource, type: :resource do
  subject(:resource) { described_class.new(sample_metadata, {}) }

  let(:sample_metadata) { create(:sample_metadata) }

  # Test attributes
  it 'has the expected attributes', :aggregate_failures do
    expect(resource).to have_attribute :cohort
    expect(resource).to have_attribute :collected_by
    expect(resource).to have_attribute :date_of_sample_collection
    expect(resource).to have_attribute :concentration
    expect(resource).to have_attribute :donor_id
    expect(resource).to have_attribute :gender
    expect(resource).to have_attribute :sample_common_name
    expect(resource).to have_attribute :sample_description
    expect(resource).to have_attribute :supplier_name
    expect(resource).to have_attribute :volume
  end

  # Updatable fields
  it 'allows updating of read-write fields', :aggregate_failures do
    expect(resource).to have_updatable_field :cohort
    expect(resource).to have_updatable_field :collected_by
    expect(resource).to have_updatable_field :date_of_sample_collection
    expect(resource).to have_updatable_field :concentration
    expect(resource).to have_updatable_field :donor_id
    expect(resource).to have_updatable_field :gender
    expect(resource).to have_updatable_field :sample_common_name
    expect(resource).to have_updatable_field :sample_description
    expect(resource).to have_updatable_field :supplier_name
    expect(resource).to have_updatable_field :volume
  end

  # Non-updatable fields -- uncomment to use
  # it 'disallows updating of read only fields', :aggregate_failures do
  #   expect(resource).not_to have_updatable_field :uuid
  # end
end
