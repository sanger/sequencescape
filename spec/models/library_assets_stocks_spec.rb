# frozen_string_literal: true
require 'rails_helper'

RSpec.describe SampleManifest, type: :model do
  describe 'Library behaviours' do
    let(:study) { create(:study) }

    context 'when asset_type is library' do
      let(:manifest) { create(:sample_manifest, study: study, asset_type: 'library') }

      it 'has stocks? set to true in core_behaviour' do
        expect(manifest.core_behaviour.stocks?).to be true
      end
    end

    context 'when asset_type is library_plate' do
      let(:manifest) { create(:sample_manifest, study: study, asset_type: 'library_plate') }

      it 'has stocks? set to true in core_behaviour' do
        expect(manifest.core_behaviour.stocks?).to be true
      end
    end
  end
end
