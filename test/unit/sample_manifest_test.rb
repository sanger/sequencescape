# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'

class SampleManifestTest < ActiveSupport::TestCase
  context '#generate' do
    setup do
      barcode = mock('barcode')
      barcode.stubs(:barcode).returns(23)
      PlateBarcode.stubs(:create).returns(barcode)

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

          should "create #{count} plate(s) and #{count * 96} wells and samples in the right study" do
            assert_equal (count * 96), Sample.count - @initial_samples
            assert_equal (count * 1), Plate.count - @initial_plates
            assert_equal (count * 96), Well.count - @initial_wells
            assert_equal (count * 96), @study.samples.count - @initial_in_study
            assert_equal (count * 96), Messenger.count - @initial_messenger_count
          end
        end

        context 'tubes' do
          setup do
            @initial_samples  = Sample.count
            @initial_tubes    = SampleTube.count
            @initial_in_study = @study.samples.count

            @manifest = create :sample_manifest, study: @study, count: 1, asset_type: '1dtube'
            @manifest.generate
          end

          should 'create 1 tubes and samples in the right study' do
            assert_equal 1, Sample.count - @initial_samples
            assert_equal 1, SampleTube.count - @initial_tubes
            assert_equal 1, @study.samples.count - @initial_in_study
          end

          should 'create create asset requests when jobs are processed' do
            # Not entirely certain this behaviour is all that useful to us.
            Delayed::Worker.new.work_off
            assert_equal SampleTube.last.requests.count, 1
            assert SampleTube.last.requests.first.is_a?(CreateAssetRequest)
          end
        end
      end
    end

    context 'for a multiplexed library' do
      [2, 3].each do |count|
        context "#{count} plate(s)" do
          setup do
            @initial_samples       = Sample.count
            @initial_library_tubes = LibraryTube.count
            @initial_mx_tubes      = MultiplexedLibraryTube.count
            @initial_in_study      = @study.samples.count

            @manifest = create :sample_manifest, study: @study, count: count, asset_type: 'multiplexed_library'
            @manifest.generate
          end

          should "create 1 tubes(s) and #{count} samples in the right study" do
            assert_equal (count), Sample.count                 - @initial_samples
            # We need to create library tubes as we have downstream dependencies that assume a unique library tube
            assert_equal (count), LibraryTube.count            - @initial_library_tubes
            assert LibraryTube.last.aliquots.first.library_id
            assert_equal (1),     MultiplexedLibraryTube.count - @initial_mx_tubes
            assert_equal (count), @study.samples.count         - @initial_in_study
          end
        end
      end
    end

    context 'for a library' do
      context 'library tubes' do
        setup do
          @initial_samples       = Sample.count
          @initial_library_tubes = LibraryTube.count
          @initial_mx_tubes      = MultiplexedLibraryTube.count
          @initial_in_study      = @study.samples.count
          @initial_tubes = SampleTube.count

          @manifest = create :sample_manifest, study: @study, count: 1, asset_type: 'library'
          @manifest.generate
        end

        should 'create 1 tubes and sample in the right study' do
          assert_equal 1, Sample.count - @initial_samples
          # We need to create library tubes as we have downstream dependencies that assume a unique library tube
          assert_equal 1, LibraryTube.count - @initial_library_tubes
          assert LibraryTube.last.aliquots.first.library_id
          assert_equal @initial_mx_tubes, MultiplexedLibraryTube.count
          assert_equal 1, @study.samples.count - @initial_in_study
          assert_equal @initial_tubes, SampleTube.count
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

          should "create #{count} tubes(s) and #{count} samples in the right study" do
            assert_equal (count), Sample.count - @initial_samples
            # We need to create library tubes as we have downstream dependencies that assume a unique library tube
            assert_equal (count), SampleTube.count - @initial_sample_tubes
            refute SampleTube.last.aliquots.first.library_id
            assert_equal (count), @study.samples.count - @initial_in_study
            assert_equal count, Messenger.count - @initial_messenger_count
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
      should 'not try to add an event to a plate' do
        assert_nothing_raised do
          SampleManifest::PlateBehaviour::Core.new(SampleManifest.new).updated_by!(
            @user, [
              @well_with_sample_and_plate.primary_aliquot.sample,
              @well_with_sample_and_without_plate.primary_aliquot.sample
            ]
          )
        end
      end
    end
    context 'where a well has a plate' do
      should 'add an event to the plate' do
        SampleManifest::PlateBehaviour::Core.new(SampleManifest.new).updated_by!(@user, [@well_with_sample_and_plate.primary_aliquot.sample])
        assert_equal Event.last, @well_with_sample_and_plate.plate.events.last
        assert_not_nil @well_with_sample_and_plate.plate.events.last
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
      PlateBarcode.stubs(:create).returns(Object.new.tap do |fudged_barcode|
        def fudged_barcode.barcode
          @barcode = (@barcode || 0) + 1
        end
      end)

      @manifest = create(:sample_manifest, count: 37, asset_type: 'plate', rapid_generation: true)
      @manifest.generate
    end

    should 'have one job per plate' do
      assert_equal(@manifest.count, Delayed::Job.count, 'number of delayed jobs does not match number of plates')
    end

    context 'delayed jobs' do
      setup do
        @well_count = Sample.count
        Delayed::Job.first.invoke_job
      end

      should 'change Well.count by 96' do
        assert_equal 96, Sample.count - @well_count, 'Expected Well.count to change by 96'
      end
    end
  end
end
