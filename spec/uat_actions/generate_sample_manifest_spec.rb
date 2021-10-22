# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GenerateSampleManifest do
  context 'with valid options' do
    let(:study) { create(:study, name: 'Test Study') }
    let(:supplier) { create(:supplier, name: 'Test Supplier') }
    let(:uat_action) { described_class.new(parameters) }

    context 'when generating a sample manfiest for a list of barcodes' do
      let(:parameters) do
        { study: study, supplier: supplier, asset_type: asset_type, count: num_assets, with_samples: with_samples }
      end

      context 'when creating tubes' do
        let(:num_assets) { 2 }
        let(:asset_type) { '1dtube' }

        context 'when specifying with samples' do
          let(:with_samples) { '1' }

          it 'generates tubes' do
            expect { uat_action.perform }.to(change { Tube.all.count }.by(2))
          end

          it 'generates samples' do
            expect { uat_action.perform }.to(change { Sample.all.count }.by(2))
          end
        end

        context 'when specifying without samples' do
          let(:with_samples) { '0' }

          it 'generates tubes' do
            expect { uat_action.perform }.to(change { Tube.all.count }.by(2))
          end

          it 'does not generate samples' do
            expect { uat_action.perform }.not_to(change { Sample.all.count })
          end
        end
      end
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
