require 'rails_helper'

# Rubocop doesn't like the .and change {}.by bits and will
# result in repeatedly indenting them to the level of the last call in the previous chain
# rubocop:disable Layout/MultilineMethodCallIndentation

RSpec.describe SampleManifest, type: :model do
  let(:user) { create :user }

  context '#default_filename' do
    let(:study) { create :study }
    let(:date) { Date.parse('25/10/2018') }
    let(:manifest) { create :sample_manifest, study: study, created_at: date }

    it 'includes the information requested' do
      expect(manifest.default_filename).to eq("#{study.id}stdy_manifest_#{manifest.id}_251018")
    end
  end

  context '#generate' do
    let(:study) { create :study }
    let(:manifest) { create :sample_manifest, study: study, count: count, asset_type: asset_type, purpose: purpose }
    let(:purpose) { nil }

    setup do
      barcode = double('barcode', barcode: 23)
      barcode2 = double('barcode', barcode: 24)
      allow(PlateBarcode).to receive(:create).and_return(barcode, barcode2)
    end

    context 'asset_type: plate' do
      let(:asset_type) { 'plate' }

      [1, 2].each do |count|
        context "count: #{count}" do
          let(:count) { count }

          it "create #{count} plate(s), #{count * 96} wells" do
            expect { manifest.generate }.to change(Plate, :count).by(count)
                                                                  .and change(Well, :count).by(count * 96)
            expect(manifest.labware.count).to eq(count)
            expect(manifest.labware.first).to be_a(Plate)
          end

          it 'create sample manifest assets' do
            expect { manifest.generate }.to change(SampleManifestAsset, :count).by(count * 96)
            wells = Plate.includes(:wells).with_barcode(manifest.barcodes).flat_map(&:wells)
            expect(manifest.assets).to eq(wells)
          end

          context 'follwing generation' do
            setup { manifest.generate }

            it 'returns the details of the created samples' do
              sample_id = SangerSampleId.order(id: :desc).limit(96 * count).last.id
              expect(manifest.details_array.length).to eq(96 * count)
              expect(manifest.details_array.first).to eq(
                barcode: 'DN23N',
                position: 'A1',
                sample_id: "WTCCC#{sample_id}"
              )
            end

            it 'create sample and aliquots' do
              sma1 = manifest.sample_manifest_assets.first
              expect { manifest.create_sample_and_aliquot(sma1.sanger_sample_id, sma1.asset) }.to change(Sample, :count).by(1)
                                                                                              .and change { study.samples.count }.by(1)
                                                                                              .and change(Messenger, :count).by(1)
              sma2 = manifest.sample_manifest_assets.last
              expect { manifest.create_sample_and_aliquot(sma2.sanger_sample_id, sma2.asset) }.to change(Sample, :count).by(1)
                                                                                              .and change { study.samples.count }.by(1)
                                                                                              .and change(Messenger, :count).by(1)
              manifest.samples.reset
              expect(manifest.samples.first.primary_aliquot.study).to eq(study)
            end
          end
        end
      end

      context 'with a custom purpose' do
        let(:purpose) { create :plate_purpose, size: 2 }
        let(:count) { 1 }
        let(:asset_type) { 'plate' }

        setup { manifest.generate }

        it 'create a plate of the correct purpose' do
          assert_equal purpose, Plate.last.purpose
        end
      end
    end

    context 'created broadcast event' do
      context 'no rapid generation' do
        let(:manifest) { create :sample_manifest, study: study }

        it 'adds created broadcast event when sample manifest is created' do
          expect { manifest.generate }.to change { BroadcastEvent::SampleManifestCreated.count }.by(1)
          broadcast_event = BroadcastEvent::SampleManifestCreated.last
          expect(broadcast_event.subjects.count).to eq 2
          expect(broadcast_event.to_json).to be_a String
        end
      end
    end

    context 'for a multiplexed library' do
      let(:asset_type) { 'multiplexed_library' }

      [2, 3].each do |count|
        context "#{count} libraries(s)" do
          let(:count) { count }

          it 'create 1 MX tube' do
            expect { manifest.generate }.to  change(LibraryTube, :count).by(count)
                                        .and change(MultiplexedLibraryTube, :count).by(1)
                                        .and change(BroadcastEvent, :count).by(1)
          end

          it 'create sample manifest asset' do
            expect { manifest.generate }.to  change(SampleManifestAsset, :count).by(count)
            expect(manifest.assets).to eq(LibraryTube.with_barcode(manifest.barcodes).sort_by(&:human_barcode))
          end

          context 'after generation' do
            setup { manifest.generate }

            it 'returns the details of the created samples' do
              sample_id = SangerSampleId.order(id: :desc).limit(count).last.id
              expect(manifest.details_array.length).to eq(count)
              expect(manifest.details_array.first).to eq(
                barcode: manifest.barcodes.first,
                sample_id: "WTCCC#{sample_id}"
              )
            end

            it 'create sample and aliquots' do
              sma = manifest.sample_manifest_assets.last
              expect { manifest.create_sample_and_aliquot(sma.sanger_sample_id, sma.asset) }.to change(Sample, :count).by(1)
                                                                                            .and change { study.samples.count }.by(1)
              expect(LibraryTube.last.aliquots.first.library).to eq(manifest.assets.last)
              manifest.samples.reset
              expect(manifest.samples.first.primary_aliquot.study).to eq(study)
            end

            describe '#labware' do
              subject { manifest.labware }

              it 'has one element' do
                expect(subject.count).to eq(1)
              end
              it 'is a multiplexed library tube' do
                expect(subject.first).to be_a(MultiplexedLibraryTube)
              end
            end
          end
        end
      end
    end

    context 'for a library' do
      let(:asset_type) { 'library' }
      let(:count) { 1 }

      context 'library tubes' do
        it 'create 1 tube' do
          # We need to create library tubes as we have downstream dependencies that assume a unique library tube
          expect { manifest.generate }.to change(LibraryTube, :count).by(count)
                                      .and change(MultiplexedLibraryTube, :count).by(0)
                                      .and change(SampleTube, :count).by(0)
                                      .and change(SampleManifestAsset, :count).by(count)
                                      .and change(BroadcastEvent, :count).by(1)
        end

        context 'once generated' do
          setup { manifest.generate }

          it 'returns the details of the created samples' do
            sample_id = SangerSampleId.order(id: :desc).limit(count).last.id
            expect(manifest.details_array.length).to eq(count)
            expect(manifest.details_array.first).to eq(
              barcode: manifest.barcodes.first,
              sample_id: "WTCCC#{sample_id}"
            )
          end

          it 'create sample manifest asset' do
            expect(manifest.assets.count).to eq(count)
            expect(manifest.assets).to eq(LibraryTube.with_barcode(manifest.barcodes))
          end

          it 'create sample and aliquots' do
            sma = manifest.sample_manifest_assets.last
            expect { manifest.create_sample_and_aliquot(sma.sanger_sample_id, sma.asset) }.to change(Sample, :count).by(1)
              .and change { study.samples.count }.by(count)
            expect(LibraryTube.last.aliquots.first.library).to eq(manifest.assets.last)
            manifest.samples.reset
            expect(manifest.samples.first.primary_aliquot.study).to eq(study)
          end

          describe '#labware' do
            subject { manifest.labware }

            it 'has one element' do
              expect(subject.count).to eq(1)
            end
            it 'is a library tube' do
              expect(subject.first).to be_a(LibraryTube)
            end
          end
        end
      end
    end

    context 'for a sample tube' do
      let(:asset_type) { '1dtube' }
      let(:purpose) { Tube::Purpose.standard_sample_tube }

      [1, 2].each do |count|
        context "#{count} tubes(s)" do
          let(:count) { count }

          it "create #{count} tubes(s)" do
            expect { manifest.generate }.to change(SampleTube, :count).by(count)
                                        .and change { manifest.assets.count }.by(count)
            expect(manifest.assets).to eq(SampleTube.with_barcode(manifest.barcodes))
          end

          context 'after generation' do
            setup { manifest.generate }

            it 'create sample and aliquots' do
              sma = manifest.sample_manifest_assets.last
              expect { manifest.create_sample_and_aliquot(sma.sanger_sample_id, sma.asset) }
                .to change(Sample, :count).by(1)
                .and change { study.samples.count }.by(1)
                .and change(Messenger, :count).by(1)
              expect(SampleTube.last.aliquots.first.library).to be_nil
              manifest.samples.reset
              expect(manifest.samples.first.primary_aliquot.study).to eq(study)
            end

            it 'create create asset requests when jobs are processed' do
              # Not entirely certain this behaviour is all that useful to us.
              Delayed::Worker.new.work_off
              expect(SampleTube.last.requests.count).to eq(1)
              expect(SampleTube.last.requests.first).to be_a(CreateAssetRequest)
            end

            describe '#labware' do
              subject { manifest.labware }

              it 'has one element' do
                expect(subject.count).to eq(count)
              end
              it 'is a sample tube' do
                expect(subject.first).to be_a(SampleTube)
              end
            end
          end
        end
      end
    end
  end

  context 'update event' do
    let(:well_with_sample_and_plate) { create :well_with_sample_and_plate }
    let(:well_with_sample_and_without_plate) { create :well_with_sample_and_without_plate }

    context 'where a well has no plate' do
      it 'not try to add an event to a plate' do
        expect do
          SampleManifest::PlateBehaviour::Core.new(SampleManifest.new).updated_by!(
            user, [
              well_with_sample_and_plate.primary_aliquot.sample,
              well_with_sample_and_without_plate.primary_aliquot.sample
            ]
          )
        end.not_to raise_error
      end
    end

    context 'where a well has a plate' do
      it 'adds an event to the plate' do
        SampleManifest::PlateBehaviour::Core.new(SampleManifest.new)
                                            .updated_by!(user,
                                                         [well_with_sample_and_plate.primary_aliquot.sample])
        expect(Event.last).to eq(well_with_sample_and_plate.plate.events.last)
        expect(well_with_sample_and_plate.plate.events.last).not_to be_nil
      end
    end
  end

  # This is testing a specific case pulled from production where the size of the delayed job 'handler' column was
  # being filled because we're passing large parameter data (it happens that ~37 plates cause this).  Because of this
  # the parameters were being truncated, ironically to create valid YAML, and the production code was erroring
  # because the last parameter was being dropped.  Good thing the plate IDs were last, right!?!!
  context 'creating extremely large manifests' do
    let(:manifest) { create(:sample_manifest, count: 37, asset_type: 'plate', rapid_generation: true) }

    setup do
      allow(PlateBarcode).to receive(:create).and_return(*Array.new(37) { |i| double('barcode', barcode: i + 1) })
      manifest.generate
    end

    it 'has one job per plate' do
      expect(Delayed::Job.count).to eq(manifest.count)
    end

    context 'delayed jobs' do
      it 'broadcast one event with two subjects' do
        expect { Delayed::Job.first.invoke_job }.to change(BroadcastEvent, :count).by 1
        expect(BroadcastEvent.last.subjects.count).to eq(2)
      end
    end
  end
end

# rubocop:enable Layout/MultilineMethodCallIndentation
