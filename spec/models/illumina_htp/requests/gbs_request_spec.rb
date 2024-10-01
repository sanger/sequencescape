# frozen_string_literal: true

require 'rails_helper'

describe IlluminaHtp::Requests::GbsRequest do
  subject(:request) { create(:gbs_request) }

  describe '#request_metadata' do
    describe '#primer_panel' do
      subject { request.request_metadata.primer_panel }

      it { is_expected.to be_a PrimerPanel }
    end
  end

  describe '#update_pool_information' do
    let(:mutated_hash) { {} }

    it 'adds primer panel' do
      subject.update_pool_information(mutated_hash)
      expect(mutated_hash.keys).to include(:primer_panel)
      expect(mutated_hash[:primer_panel]).to eq(request.request_metadata.primer_panel.summary_hash)
    end
  end
end
