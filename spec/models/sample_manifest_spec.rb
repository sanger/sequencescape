# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'rails_helper'

RSpec.describe SampleManifest, type: :model do
  context '#generate' do
    setup do
      barcode = double('barcode')
      allow(barcode).to receive(:barcode).and_return(23)
      allow(PlateBarcode).to receive(:create).and_return(barcode)

      @study = create :study, name: 'CARD1'
      @study.study_metadata.study_name_abbreviation = 'CARD1'
      @study.save!
    end

    context 'creates the right assets' do
      [1, 2].each do |count|
        context "#{count} plate(s)" do
          setup do
            @initial_samples  = Sample.count
            @initial_plates   = Plate.count
            @initial_wells    = Well.count
            @initial_in_study = @study.samples.count
            @initial_messenger_count = Messenger.count

            @manifest = create :sample_manifest, study: @study, count: count
            @manifest.generate
          end

          it "should create #{count} plate(s) and #{count * 96} wells and samples in the right study" do
            assert_equal (count * 96), Sample.count - @initial_samples
            assert_equal (count * 1), Plate.count - @initial_plates
            assert_equal (count * 96), Well.count - @initial_wells
            assert_equal (count * 96), @study.samples.count - @initial_in_study
            assert_equal (count * 96), Messenger.count - @initial_messenger_count
            # This test is a bit overloaded for performance reasons.
            expect(@manifest.labware.count).to eq(count)
            expect(@manifest.labware.first).to be_a(Plate)
          end
        end
      end

      context 'with a custom purpose' do
        setup do
          @purpose = create :plate_purpose
          @manifest = create :sample_manifest, study: @study, count: 1, purpose: @purpose
          @manifest.generate
        end

        it 'should create a plate of the correct purpose' do
          assert_equal @purpose, Plate.last.purpose
        end
      end
    end

    context 'for a multiplexed library' do
      [2, 3].each do |count|
        context "#{count} libraries(s)" do
          setup do
            @initial_samples       = Sample.count
            @initial_library_tubes = LibraryTube.count
            @initial_mx_tubes      = MultiplexedLibraryTube.count
            @initial_in_study      = @study.samples.count

            @manifest = create :sample_manifest, study: @study, count: count, asset_type: 'multiplexed_library'
            @manifest.generate
          end

          it "should create 1 tubes(s) and #{count} samples in the right study" do
            assert_equal count, Sample.count                 - @initial_samples
            # We need to create library tubes as we have downstream dependencies that assume a unique library tube
            assert_equal count, LibraryTube.count            - @initial_library_tubes
            assert LibraryTube.last.aliquots.first.library_id
            assert_equal 1,     MultiplexedLibraryTube.count - @initial_mx_tubes
            assert_equal count, @study.samples.count         - @initial_in_study
          end

          describe '#labware' do
            subject { @manifest.labware }
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
      setup do
        @initial_samples       = Sample.count
        @initial_library_tubes = LibraryTube.count
        @initial_mx_tubes      = MultiplexedLibraryTube.count
        @initial_in_study      = @study.samples.count
        @initial_tubes = SampleTube.count

        @manifest = create :sample_manifest, study: @study, count: 1, asset_type: 'library'
        @manifest.generate
      end

      it 'should create 1 tubes and sample in the right study' do
        assert_equal 1, Sample.count - @initial_samples
        # We need to create library tubes as we have downstream dependencies that assume a unique library tube
        assert_equal 1, LibraryTube.count - @initial_library_tubes
        assert LibraryTube.last.aliquots.first.library_id
        assert_equal @initial_mx_tubes, MultiplexedLibraryTube.count
        assert_equal 1, @study.samples.count - @initial_in_study
        assert_equal @initial_tubes, SampleTube.count
      end

      describe '#labware' do
        subject { @manifest.labware }
        it 'has one element' do
          expect(subject.count).to eq(1)
        end
        it 'is a library tube' do
          expect(subject.first).to be_a(LibraryTube)
        end
      end
    end

    context 'for a sample tube' do
      [1, 2].each do |count|
        context "#{count} tubes(s)" do
          setup do
            @initial_samples = Sample.count
            @initial_sample_tubes = SampleTube.count
            @initial_in_study = @study.samples.count
            @initial_messenger_count = Messenger.count

            @manifest = create :sample_manifest, study: @study, count: count, asset_type: '1dtube'
            @manifest.generate
          end

          it "should create #{count} tubes(s) and #{count} samples in the right study" do
            assert_equal count, Sample.count - @initial_samples
            # We need to create library tubes as we have downstream dependencies that assume a unique library tube
            assert_equal count, SampleTube.count - @initial_sample_tubes
            refute SampleTube.last.aliquots.first.library_id
            assert_equal count, @study.samples.count - @initial_in_study
            assert_equal count, Messenger.count - @initial_messenger_count
          end
          it 'should create create asset requests when jobs are processed' do
            # Not entirely certain this behaviour is all that useful to us.
            Delayed::Worker.new.work_off
            assert_equal SampleTube.last.requests.count, 1
            assert SampleTube.last.requests.first.is_a?(CreateAssetRequest)
          end
          describe '#labware' do
            subject { @manifest.labware }
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
    setup do
      @user = create :user
      @well_with_sample_and_plate = create :well_with_sample_and_plate
      @well_with_sample_and_plate.save
    end
    context 'where a well has no plate' do
      setup do
        @well_with_sample_and_without_plate = create :well_with_sample_and_without_plate
      end
      it 'should not try to add an event to a plate' do
        expect do
          SampleManifest::PlateBehaviour::Core.new(SampleManifest.new).updated_by!(
            @user, [
              @well_with_sample_and_plate.primary_aliquot.sample,
              @well_with_sample_and_without_plate.primary_aliquot.sample
            ]
          )
        end.not_to raise_error
      end
    end
    context 'where a well has a plate' do
      it 'should add an event to the plate' do
        SampleManifest::PlateBehaviour::Core.new(SampleManifest.new).updated_by!(@user, [@well_with_sample_and_plate.primary_aliquot.sample])
        assert_equal Event.last, @well_with_sample_and_plate.plate.events.last
        expect(@well_with_sample_and_plate.plate.events.last).not_to be_nil
      end
    end
  end

  # This is testing a specific case pulled from production where the size of the delayed job 'handler' column was
  # being filled because we're passing large parameter data (it happens that ~37 plates cause this).  Because of this
  # the parameters were being truncated, ironically to create valid YAML, and the production code was erroring
  # because the last parameter was being dropped.  Good thing the plate IDs were last, right!?!!
  context 'creating extremely large manifests' do
    setup do
      # Stub out the behaviour of PlateBarcode so that it can be "fudged"
      allow(PlateBarcode).to receive(:create).and_return(Object.new.tap do |fudged_barcode|
        def fudged_barcode.barcode
          @barcode = (@barcode || 0) + 1
        end
      end)

      @manifest = create(:sample_manifest, count: 37, asset_type: 'plate', rapid_generation: true)
      @manifest.generate
    end

    it 'should have one job per plate' do
      assert_equal(@manifest.count, Delayed::Job.count, 'number of delayed jobs does not match number of plates')
    end

    context 'delayed jobs' do
      setup do
        @well_count = Sample.count
        Delayed::Job.first.invoke_job
      end

      it 'should change Well.count by 96' do
        assert_equal 96, Sample.count - @well_count, 'Expected Well.count to change by 96'
      end
    end
  end
end
