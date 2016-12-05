#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012,2014,2015,2016 Genome Research Ltd.

require "test_helper"

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

  context "A Sample" do
    should have_many :study_samples
    should have_many :studies

    context "when used in older assets" do
      setup do
        @sample = create :sample
        @tube_a = create :empty_library_tube
        @tube_b = create :empty_sample_tube

       create(:aliquot, sample: @sample, receptacle: @tube_b)
       create(:aliquot, sample: @sample, receptacle: @tube_a)
      end

      should "have the first tube it was added to as a primary asset" do
        assert_equal @sample.reload.primary_receptacle, @tube_b
      end
    end

    context "#accession_number?" do
      setup do
        @sample = create :sample
      end
      context "with nil accession number" do
        setup do
          @sample.sample_metadata.sample_ebi_accession_number = nil
        end
        should "return false" do
          assert !@sample.accession_number?
        end
      end
      context "with a blank accession number" do
        setup do
          @sample.sample_metadata.sample_ebi_accession_number = ''
        end
        should "return false" do
          assert !@sample.accession_number?
        end
      end
      context "with a valid accession number" do
        setup do
          @sample.sample_metadata.sample_ebi_accession_number = 'ERS00001'
        end
        should "return true" do
          assert @sample.accession_number?
        end
      end
    end

    context "#accession service" do
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

    context "accessioning" do

      attr_reader :metadata_with_an, :metadata_wo_an

      setup do
        create(:user, api_key: configatron.accession_local_key)
        @metadata_with_an = {sample_taxon_id: "1", sample_common_name: "A common name", sample_ebi_accession_number: "ENA123" }
        @metadata_wo_an = metadata_with_an.except(:sample_ebi_accession_number)
      end

      should 'proceed if the sample meets accessioning requirements' do
        assert create(:sample, studies: [create(:open_study)], sample_metadata: Sample::Metadata.new(metadata_wo_an)).accessionable?
      end

      should 'not proceed if the sample has already been accessioned' do

        refute create(:sample, studies: [create(:open_study, accession_number: 'ENA123')], sample_metadata: Sample::Metadata.new(metadata_with_an)).accessionable?
      end

      should 'not proceed if the sample metadata has no taxon and common name' do
        refute create(:sample, sample_metadata: Sample::Metadata.new(metadata_wo_an.except(:sample_taxon_id))).accessionable?
        refute create(:sample, sample_metadata: Sample::Metadata.new(metadata_wo_an.except(:sample_common_name))).accessionable?
      end

      should 'not proceed if the studies are not suitable' do
        open_study = create(:open_study)
        assert create(:sample, studies: [open_study], sample_metadata: Sample::Metadata.new(metadata_wo_an)).accessionable?
        assert create(:sample, studies: [create(:managed_study)], sample_metadata: Sample::Metadata.new(metadata_wo_an)).accessionable?
        refute create(:sample, studies: [create(:not_app_study)], sample_metadata: Sample::Metadata.new(metadata_wo_an)).accessionable?
        open_study.study_metadata.update_attributes(data_release_timing: Study::DATA_RELEASE_TIMING_NEVER, data_release_prevention_reason: 'data validity', data_release_prevention_approval: 'Yes', data_release_prevention_reason_comment: "blah, blah, blah") 
        refute create(:sample, studies: [open_study], sample_metadata: Sample::Metadata.new(metadata_wo_an)).accessionable?
      end

      should 'not proceed if the current user is not valid' do
        configatron.accession_local_key = nil
        refute create(:sample, studies: [create(:open_study)], sample_metadata: Sample::Metadata.new(metadata_wo_an)).accessionable?
        configatron.accession_local_key = "abc"
      end

      context 'delayed job' do

        setup do
          Delayed::Worker.delay_jobs = false
          WebMock.stub_request(:post, "#{configatron.accession_url}#{configatron.ena_accession_login}").to_return( {
            headers: {'Content-Type' => 'text/xml'},
            body: '<RECEIPT success="true"><SAMPLE accession="EGA00001000240" /></RECEIPT>',
            status: 200
          })
        end

        should 'succeed if the sample is acccessionable' do
          sample = create(:sample, studies: [create(:open_study, accession_number: 'ENA123')], sample_metadata: Sample::Metadata.new(metadata_wo_an))
          Delayed::Job.enqueue SampleAccessioningJob.new(sample)
          assert(sample.sample_metadata.sample_ebi_accession_number.present?)
        end

        should 'fail if the sample is not accessionable' do
          sample = create(:sample, studies: [create(:open_study)], sample_metadata: Sample::Metadata.new(metadata_wo_an.except(:sample_taxon_id)))
          Delayed::Job.enqueue SampleAccessioningJob.new(sample)
          refute(sample.sample_metadata.sample_ebi_accession_number.present?)
        end

        teardown do
          Delayed::Worker.delay_jobs = true
        end
      end

    end
  end

end
