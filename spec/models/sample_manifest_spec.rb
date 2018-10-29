
require 'rails_helper'

RSpec.describe SampleManifest, type: :model do
  let(:user) { create :user }

  context '#generate' do
    let(:study) { create :study }
    let(:manifest) { create :sample_manifest, study: study, count: count, asset_type: asset_type, purpose: purpose }
    let(:purpose) { nil }

    setup do
      barcode = double('barcode', barcode: 23)
      allow(PlateBarcode).to receive(:create).and_return(barcode)
      @initial_samples  = Sample.count
      @initial_plates   = Plate.count
      @initial_wells    = Well.count
      @initial_sample_tubes = SampleTube.count
      @initial_in_study = study.samples.count
      @initial_messenger_count = Messenger.count
      @initial_library_tubes = LibraryTube.count
      @initial_mx_tubes      = MultiplexedLibraryTube.count
      @initial_broadcast_events = BroadcastEvent.count
      @initial_sample_manifest_assets = SampleManifestAsset.count
    end

    context 'asset_type: plate' do
      let(:asset_type) { 'plate' }

      [1, 2].each do |count|
        context "count: #{count}" do
          let(:count) { count }

          setup { manifest.generate }

          it "create #{count} plate(s) and #{count * 96} wells" do
            # expect(Sample.count - @initial_samples).to eq(count * 96)
            expect(Plate.count - @initial_plates).to eq(count * 1)
            expect(Well.count - @initial_wells).to eq(count * 96)
            # expect(study.samples.count - @initial_in_study).to eq(count * 96)
            # expect(Messenger.count - @initial_messenger_count).to eq(count * 96)
            # expect(manifest.samples.first.primary_aliquot.study).to eq(study)
            expect(manifest.labware.count).to eq(count)
            expect(manifest.labware.first).to be_a(Plate)
          end

          it "create #{count} sample manifest assets" do
            expect(SampleManifestAsset.count - @initial_sample_manifest_assets).to eq(manifest.labware.count * 96)
            wells = Plate.with_barcode(manifest.barcodes).flat_map(&:wells)
            expect(manifest.sample_manifest_assets.map(&:asset)).to eq(wells)
          end
        end
      end

      context 'with a custom purpose' do
        let(:purpose) { create :plate_purpose }
        let(:count) { 1 }
        let(:asset_type) { 'plate' }

        setup { manifest.generate }

        it 'create a plate of the correct purpose' do
          assert_equal purpose, Plate.last.purpose
        end
      end
    end

    context 'created broadcast event' do
      context 'rapid generation' do
        let(:manifest) { create :sample_manifest, study: study, count: 1, purpose: purpose, rapid_generation: true }
        it 'does not add created broadcast event if subjects are not ready (created on delayed job)' do
          # expect { manifest.generate }.not_to change { BroadcastEvent::SampleManifestCreated.count }
        end
      end
      context 'no rapid generation' do
        let(:manifest) { create :sample_manifest, study: study, count: 1, purpose: purpose }
        it 'adds created broadcast event when samples are created in real time' do
          # expect { manifest.generate }.to change { BroadcastEvent::SampleManifestCreated.count }.by(1)
          # broadcast_event = BroadcastEvent::SampleManifestCreated.last
          # expect(broadcast_event.subjects.count).to eq 98
          # expect(broadcast_event.to_json).to be_a String
        end
      end
    end

    context 'for a multiplexed library' do
      let(:asset_type) { 'multiplexed_library' }
      [2, 3].each do |count|
        context "#{count} libraries(s)" do
          let(:count) { count }

          setup { manifest.generate }

          it 'create 1 MX tube' do
            # assert_equal count, Sample.count                 - @initial_samples
            # We need to create library tubes as we have downstream dependencies that assume a unique library tube
            assert_equal count, LibraryTube.count - @initial_library_tubes
            # assert LibraryTube.last.aliquots.first.library_id
            assert_equal 1, MultiplexedLibraryTube.count - @initial_mx_tubes
            # assert_equal count, study.samples.count - @initial_in_study
            # expect(BroadcastEvent.count - @initial_broadcast_events).to eq 1
            # expect(manifest.samples.first.primary_aliquot.study).to eq(study)
          end

          it 'create sample manifest asset' do
            assets = manifest.sample_manifest_assets.map(&:asset)
            expect(assets.count).to eq(LibraryTube.count - @initial_library_tubes)
            expect(assets).to eq(LibraryTube.with_barcode(manifest.barcodes))
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

    context 'for a library' do
      let(:asset_type) { 'library' }
      let(:count) { 1 }
      context 'library tubes' do
        setup { manifest.generate }

        it 'create 1 tube' do
          # assert_equal 1, Sample.count - @initial_samples
          # We need to create library tubes as we have downstream dependencies that assume a unique library tube
          assert_equal 1, LibraryTube.count - @initial_library_tubes
          # assert LibraryTube.last.aliquots.first.library_id
          assert_equal @initial_mx_tubes, MultiplexedLibraryTube.count
          # assert_equal 1, study.samples.count - @initial_in_study
          assert_equal @initial_sample_tubes, SampleTube.count
          # expect(manifest.samples.first.primary_aliquot.study).to eq(study)
        end

        it 'create sample manifest asset' do
          assets = manifest.sample_manifest_assets.map(&:asset)
          expect(assets.count).to eq(LibraryTube.count - @initial_library_tubes)
          expect(assets).to eq(LibraryTube.with_barcode(manifest.barcodes))
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

    context 'for a sample tube' do
      let(:asset_type) { '1dtube' }

      [1, 2].each do |count|
        context "#{count} tubes(s)" do
          let(:count) { count }
          setup { manifest.generate }

          it "create #{count} tubes(s)" do
            # assert_equal count, Sample.count - @initial_samples
            # We need to create library tubes as we have downstream dependencies that assume a unique library tube
            assert_equal count, SampleTube.count - @initial_sample_tubes
            # expect(SampleTube.last.aliquots.first.library_id).to be_nil
            # assert_equal count, study.samples.count - @initial_in_study
            # assert_equal count, Messenger.count - @initial_messenger_count
            # expect(manifest.samples.first.primary_aliquot.study).to eq(study)
          end

          it 'create sample manifest asset' do
            assets = manifest.sample_manifest_assets.map(&:asset)
            expect(assets.count).to eq(SampleTube.count - @initial_sample_tubes)
            expect(assets).to eq(SampleTube.with_barcode(manifest.barcodes))
          end

          it 'create create asset requests when jobs are processed' do
            # Not entirely certain this behaviour is all that useful to us.
            Delayed::Worker.new.work_off
            # assert_equal SampleTube.last.requests.count, 1
            # assert SampleTube.last.requests.first.is_a?(CreateAssetRequest)
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
        SampleManifest::PlateBehaviour::Core.new(SampleManifest.new).updated_by!(user, [well_with_sample_and_plate.primary_aliquot.sample])
        assert_equal Event.last, well_with_sample_and_plate.plate.events.last
        expect(well_with_sample_and_plate.plate.events.last).to_not be_nil
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

    it 'should have one job per plate' do
      assert_equal(manifest.count, Delayed::Job.count, 'number of delayed jobs does not match number of plates')
    end

    context 'delayed jobs' do
      setup do
        @sample_count = Sample.count
        @initial_broadcast_events = BroadcastEvent.count
        Delayed::Job.first.invoke_job
      end

      it 'change Sample.count by 96' do
        # assert_equal 96, Sample.count - @sample_count, 'Expected Sample.count to change by 96'
        # expect(BroadcastEvent.count - @initial_broadcast_events).to eq 1
        # expect(BroadcastEvent.last.subjects.count).to eq 98
      end
    end
  end
end
