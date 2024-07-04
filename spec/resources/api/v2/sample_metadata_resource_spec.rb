# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/sample_metadata_resource'

RSpec.describe Api::V2::SampleMetadataResource, type: :resource do
  describe 'it works' do
    subject { described_class.new(sample_metadata, {}) }

    let(:sample_metadata) { create(:sample_metadata) }

    it 'has the expected attributes' do
      expect(subject).to have_attribute :sample_common_name
      expect(subject).to have_attribute :supplier_name
      expect(subject).to have_attribute :collected_by
      expect(subject).to have_attribute :donor_id
      expect(subject).to have_attribute :concentration
      expect(subject).to have_attribute :volume
    end
  end
end
