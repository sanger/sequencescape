# frozen_string_literal: true

require 'rails_helper'

describe BaitLibraryType do
  context 'When a bait library exists' do
    let(:bait_library) { create(:bait_library) }

    it 'bait libraries have library types' do
      expect(bait_library.bait_library_type).to be_truthy
    end

    it 'has a category' do
      standard_bait_library_type = described_class.new(name: 'Standard - test')
      expect(standard_bait_library_type.valid?).to be false
      standard_bait_library_type.category = 'standard'
      expect(standard_bait_library_type.valid?).to be true
      expect(standard_bait_library_type.category).to eq 'standard'
      custom_bait_library_type = described_class.new(name: 'Custom', category: 'custom')
      expect(custom_bait_library_type.category).to eq 'custom'
      expect { custom_bait_library_type.category = 'some_category' }.to raise_error ArgumentError
    end
  end

  context 'A request with a bait library' do
    let(:request_type) { create(:request_type, name: 'Bait Pulldown', target_asset_type: nil) }
    let(:request) { create(:isc_request) }

    it 'have a bait library type' do
      expect(request.request_metadata.bait_library.bait_library_type).to be_truthy
    end
  end
end
