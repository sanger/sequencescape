require 'rails_helper'
require './app/resources/api/v2/sample/metadatum_resource'

RSpec.describe Api::V2::SampleMetadataResource, type: :resource do
  describe 'it works' do
    let(:sample_metadata) { create(:sample_metadata) }
    subject { described_class.new(sample_metadata, {}) }

    it 'has the expected attributes' do
      is_expected.to have_attribute :sample_common_name
    end

  end
end
