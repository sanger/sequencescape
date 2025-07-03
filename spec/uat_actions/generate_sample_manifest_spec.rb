# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GenerateSampleManifest do
  context 'with valid options' do
    let(:study) { create(:study, name: 'Test Study') }
    let(:supplier) { create(:supplier, name: 'Test Supplier') }
    let(:uat_action) { described_class.new(parameters) }
    let(:count) { 2 }
    let(:asset_type) { '1dtube' }
    let(:with_samples) { '1' }
    let(:purpose) { create(:sample_tube_purpose, name: 'LCA Blood Vac') }
    let(:parameters) do
      {
        study_name: study.name,
        supplier_name: supplier.name,
        asset_type: asset_type,
        count: count,
        tube_purpose_name: purpose.name,
        with_samples: with_samples
      }
    end

    describe '#perform' do
      context 'when generating a sample manifest for a list of barcodes' do
        context 'when creating tubes' do
          context 'when specifying with samples' do
            let(:with_samples) { '1' }

            it 'generates tubes' do
              expect { uat_action.perform }.to(change(Tube, :count).by(2))
            end

            it 'generates samples' do
              expect { uat_action.perform }.to(change(Sample, :count).by(2))
            end

            it 'links to those samples' do
              uat_action.perform
              expect(SampleManifest.last.samples.count).to eq count
            end
          end

          context 'when specifying without samples' do
            let(:with_samples) { '0' }

            it 'generates tubes' do
              expect { uat_action.perform }.to(change(Tube, :count).by(2))
            end

            it 'does not generate samples' do
              expect { uat_action.perform }.not_to(change(Sample, :count))
            end
          end
        end

        it 'creates the sample manifest' do
          expect { uat_action.perform }.to change(SampleManifest, :count).by 1
        end

        it 'creates the sample manifest with the correct data' do
          uat_action.perform
          expect(SampleManifest.last.study).to eq study
          expect(SampleManifest.last.supplier).to eq supplier
        end
      end
    end

    describe '#create_sample_manifest' do
      let(:manifest) { create(:sample_manifest, study:, supplier:, count:, asset_type:, purpose:) }

      it 'sets the created sample manifest' do
        allow(SampleManifest).to receive(:create!).and_return(manifest)
        result = uat_action.create_sample_manifest
        expect(result).to eq manifest
      end
    end

    describe '#generate_manifest' do
      let(:manifest) { create(:sample_manifest, study:, supplier:, count:, asset_type:, purpose:) }

      it 'create tubes(s)' do
        expect { uat_action.generate_manifest(manifest) }.to change(SampleTube, :count).by(count).and change {
          manifest.assets.count
        }.by(count)
        expect(manifest.assets).to eq(SampleTube.with_barcode(manifest.barcodes).map(&:receptacle))
      end

      it 'create sample and aliquots' do
        expect { uat_action.generate_manifest(manifest) }.to change(Sample, :count)

        manifest.samples.reset
        expect(manifest.details_array.length).to eq(count)
        expect(manifest.samples.count).to eq(count)
        expect(manifest.samples.first.primary_aliquot.study).to eq(study)
      end

      it 'creates sample with sample metatdata' do
        uat_action.generate_manifest(manifest)
        manifest.samples.reset
        expect(manifest.samples.first.sample_metadata).to be_present
        expect(manifest.samples.first.sample_metadata.collected_by).to eq 'Sanger'
      end
    end
  end

  describe '#default' do
    it 'returns a default' do
      expect(described_class.default).to be_a described_class
    end
  end

  describe '#valid?' do
    let(:uat_action) { described_class.new(parameters) }

    describe '#validate_tube_purpose_exists' do
      let(:parameters) { { tube_purpose_name: } }
      let(:error_message) { format(described_class::ERROR_TUBE_PURPOSE_DOES_NOT_EXIST, tube_purpose_name) }

      context 'when the tube purpose does not exist' do
        let(:tube_purpose_name) { 'Invalid Tube Purpose' }

        it 'adds the error message' do
          expect(uat_action.valid?).to be false
          expect(uat_action.errors[:tube_purpose_name]).to include(error_message)
        end
      end

      context 'when the tube purpose exists' do
        let(:tube) { create(:tube) } # Tube to get the purpose from
        let(:tube_purpose_name) { tube.purpose.name }

        it 'does not add the error message' do
          uat_action.valid? # run validations
          expect(uat_action.errors[:tube_purpose_name]).not_to include(error_message)
        end
      end
    end
  end
end
