# This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2007-2011,2012,2014,2015,2016 Genome Research Ltd.

require 'test_helper'

class SampleTest < ActiveSupport::TestCase
    def assert_accession_service(type)
      service = {
        ega: EgaAccessionService,
        ena: EnaAccessionService,
        none: NoAccessionService,
        unsuitable: UnsuitableAccessionService
      }[type]
      assert @sample.accession_service.is_a?(service), "Sent to #{@sample.accession_service.provider} not #{type}"
    end

  context 'A Sample' do
    should have_many :study_samples
    should have_many :studies

    context 'when used in older assets' do
      setup do
        @sample = create :sample
        @tube_a = create :empty_library_tube
        @tube_b = create :empty_sample_tube

       create(:aliquot, sample: @sample, receptacle: @tube_b)
       create(:aliquot, sample: @sample, receptacle: @tube_a)
      end

      should 'have the first tube it was added to as a primary asset' do
        assert_equal @sample.reload.primary_receptacle, @tube_b
      end
    end

    context '#accession_number?' do
      setup do
        @sample = create :sample
      end
      context 'with nil accession number' do
        setup do
          @sample.sample_metadata.sample_ebi_accession_number = nil
        end
        should 'return false' do
          assert !@sample.accession_number?
        end
      end
      context 'with a blank accession number' do
        setup do
          @sample.sample_metadata.sample_ebi_accession_number = ''
        end
        should 'return false' do
          assert !@sample.accession_number?
        end
      end
      context 'with a valid accession number' do
        setup do
          @sample.sample_metadata.sample_ebi_accession_number = 'ERS00001'
        end
        should 'return true' do
          assert @sample.accession_number?
        end
      end
    end

    context '#accession service' do
      context 'with one study' do
        setup do
          @sample = create :sample
          @study = create :open_study, accession_number: 'ENA123'
          create :study_sample, study: @study, sample: @sample
        end
        should 'delegate to the study' do
          assert_equal @study, @sample.primary_study
          assert_accession_service(:ena)
        end
      end
      context 'with one un-accessioned study' do
        setup do
          @sample = create :sample
          @study = create :open_study
          create :study_sample, study: @study, sample: @sample
        end
        should 'not delegate to the study' do
          assert_accession_service(:unsuitable)
        end
      end
      context 'with one un-accessioned, never study' do
        setup do
          @sample = create :sample
          @study = create :not_app_study
          create :study_sample, study: @study, sample: @sample
        end
        should 'not delegate to the study' do
          assert_accession_service(:none)
        end
      end

      # We priorities the ega, as its the more conservative of the two
      # and it reduces the risk of accidentally making human data public
      context 'with an ena and an ega study' do
        setup do
          @sample = create :sample
          @study = create :open_study, accession_number: 'ENA123'
          @study_b = create :managed_study, accession_number: 'ENA123'
          create :study_sample, study: @study, sample: @sample
          create :study_sample, study: @study_b, sample: @sample
        end
        should 'delegate to the ega study' do
          assert_accession_service(:ega)
        end
      end

      context 'with an ena and an ega study in the other order' do
        setup do
          @sample = create :sample
          @study = create :open_study, accession_number: 'ENA123'
          @study_b = create :managed_study, accession_number: 'ENA123'
          create :study_sample, study: @study_b, sample: @sample
          create :study_sample, study: @study, sample: @sample
        end
        should 'still delegate to the ega study' do
          assert_accession_service(:ega)
        end
      end

      # We err on the side of caution here. Sending stuff to the ENA
      # could be an issue.
      context 'with an accessioned ena but un-accessioned ena' do
        setup do
          @sample = create :sample
          @study = create :open_study, accession_number: 'ENA123'
          @study_b = create :managed_study
          create :study_sample, study: @study_b, sample: @sample
          create :study_sample, study: @study, sample: @sample
        end
        should 'not delegate to either study' do
          assert_accession_service(:unsuitable)
        end
      end
    end
  end
end
