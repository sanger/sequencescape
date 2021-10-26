# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GenerateSampleManifest do
  context 'with valid options' do
    let(:study) { create(:study, name: 'Test Study') }
    let(:supplier) { create(:supplier, name: 'Test Supplier') }
    let(:uat_action) { described_class.new(parameters) }
    let(:num_assets) { 2 }
    let(:asset_type) { '1dtube' }
    let(:with_samples) { '1' }
    let(:tube_purpose_name) { 'LCA Blood Vac' }

    context 'when generating a sample manfiest for a list of barcodes' do
      let(:parameters) do
        { study_name: study.name, supplier_name: supplier.name, asset_type: asset_type, count: num_assets, tube_purpose_name: tube_purpose_name, with_samples: with_samples }
      end

      context 'when creating tubes' do
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

      it 'creates the sample manfiest' do
        expect { uat_action.perform }.to change(SampleManifest, :count).by 1
        # expect(Tube.find_by_barcode(report['tube_0']).barcode).to eq tube1
        # expect(Tube.find_by_barcode(report['tube_1']).barcode).to eq tube2
      end

      it 'creates the sample manifest with the correct data' do
        uat_action.perform
        expect(SampleManifest.last.study).to eq study
        expect(SampleManifest.last.supplier).to eq supplier
      end
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
