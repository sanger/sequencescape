# frozen_string_literal: true

require 'rails_helper'

describe IlluminaHtp::Requests::HeronTailedRequest, :heron do
  subject(:request) { build(:heron_tailed_request) }

  describe '#request_metadata' do
    describe '#primer_panel' do
      subject { request.request_metadata.primer_panel }

      it { is_expected.to be_a PrimerPanel }
    end
  end

  describe '#update_pool_information' do
    let(:mutated_hash) { {} }

    it 'adds primer panel' do
      request.update_pool_information(mutated_hash)
      expect(mutated_hash.keys).to include(:primer_panel)
      expect(mutated_hash[:primer_panel]).to eq(request.request_metadata.primer_panel.summary_hash)
    end
  end

  describe '#aliquot_attributes' do
    it 'includes a library_id' do
      expect(request.aliquot_attributes).to have_key(:library_id)
      expect(request.aliquot_attributes[:library_id]).to eq(request.asset_id)
    end
  end
end
