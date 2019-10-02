# frozen_string_literal: true

require 'rails_helper'
require 'support/barcode_helper'
require 'sample_accessioning_job'

RSpec.describe Sample, type: :model, accession: true, aker: true do
  include MockAccession

  context 'accessioning' do
    let!(:user) { create(:user, api_key: configatron.accession_local_key) }

    before do
      configatron.accession_samples = true
      Delayed::Worker.delay_jobs = false
      Accession.configure do |config|
        config.folder = File.join('spec', 'data', 'accession')
        config.load!
      end
    end

    after do
      Delayed::Worker.delay_jobs = true
      configatron.accession_samples = false
    end

    it 'will not proceed if the sample is not suitable' do
      sample = create(:sample_for_accessioning_with_open_study, sample_metadata: create(:sample_metadata_for_accessioning, sample_taxon_id: nil))
      expect(sample.sample_metadata.sample_ebi_accession_number).to be_nil
    end

    it 'will add an accession number and common name if successful' do
      allow_any_instance_of(RestClient::Resource).to receive(:post).and_return(successful_accession_response)
      sample = create(:sample_for_accessioning_with_open_study, sample_metadata: create(:sample_metadata_for_accessioning))
      expect(sample.sample_metadata.sample_ebi_accession_number).to be_present
      expect(sample.sample_metadata.sample_common_name).to be_present
    end

    it 'will not add an accession number or common name if it fails' do
      allow_any_instance_of(RestClient::Resource).to receive(:post).and_return(failed_accession_response)
      sample = build(:sample_for_accessioning_with_open_study, sample_metadata: create(:sample_metadata_for_accessioning))
      expect { sample.save! }.to raise_error(JobFailed)
      expect(sample.sample_metadata.sample_ebi_accession_number).to be_nil
      expect(sample.sample_metadata.sample_common_name).to be_nil
    end
  end

  context 'can be included in submission' do
    it 'knows if it was registered through manifest' do
      stand_alone_sample = create :sample
      expect(stand_alone_sample).not_to be_registered_through_manifest

      sample_manifest = create :tube_sample_manifest_with_samples
      sample_manifest.samples.each do |sample|
        expect(sample).to be_registered_through_manifest
      end
    end

    it 'knows when it can be included in submission if it was registered through manifest' do
      sample_manifest = create :tube_sample_manifest_with_samples
      sample_manifest.samples.each do |sample|
        expect(sample).not_to be_can_be_included_in_submission
      end
      sample = sample_manifest.samples.first
      sample.sample_metadata.supplier_name = 'new sample'
      expect(sample).to be_can_be_included_in_submission
    end

    it 'knows when it can be included in submission if it was not registered through manifest' do
      sample = create :sample
      expect(sample).to be_can_be_included_in_submission
    end
  end

  context 'Aker' do
    include BarcodeHelper
    before do
      mock_plate_barcode_service
    end

    it 'can have many work orders' do
      job = create(:aker_job)
      expect(create(:sample, jobs: [job]).jobs).to include(job)
    end

    it 'can belong to a container' do
      container = create(:container)
      expect(create(:sample, container: container).container).to eq(container)
    end
  end
end
