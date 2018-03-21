require 'rails_helper'

RSpec.describe Sample, type: :model, accession: true do
  include MockAccession

  context 'accessioning' do
    let!(:user) { create(:user, api_key: configatron.accession_local_key) }

    before(:each) do
      configatron.accession_samples = true
      Delayed::Worker.delay_jobs = false
      Accession.configure do |config|
        config.folder = File.join('spec', 'data', 'accession')
        config.load!
      end
    end

    after(:each) do
      Delayed::Worker.delay_jobs = true
      configatron.accession_samples = false
    end

    it 'will not proceed if the sample is not suitable' do
      sample = create(:sample_for_accessioning_with_open_study, sample_metadata: create(:sample_metadata_for_accessioning, sample_taxon_id: nil))
      expect(sample.sample_metadata.sample_ebi_accession_number).to be_nil
    end

    it 'will add an accession number if successful' do
      allow_any_instance_of(RestClient::Resource).to receive(:post).and_return(successful_accession_response)
      sample = create(:sample_for_accessioning_with_open_study, sample_metadata: create(:sample_metadata_for_accessioning))
      expect(sample.sample_metadata.sample_ebi_accession_number).to be_present
    end

    it 'will not add an accession number if it fails' do
      allow_any_instance_of(RestClient::Resource).to receive(:post).and_return(failed_accession_response)
      sample = create(:sample_for_accessioning_with_open_study, sample_metadata: create(:sample_metadata_for_accessioning))
      expect(sample.sample_metadata.sample_ebi_accession_number).to be_nil
    end
  end

  context 'can be included in submission' do
    it 'knows if it was registered through manifest' do
      stand_alone_sample = create :sample
      expect(stand_alone_sample.registered_through_manifest?).to be_falsey

      sample_manifest = create :tube_sample_manifest_with_samples
      sample_manifest.samples.each do |sample|
        expect(sample.registered_through_manifest?).to be_truthy
      end
    end

    it 'knows when it can be included in submission if it was registered through manifest' do
      sample_manifest = create :tube_sample_manifest_with_samples
      sample_manifest.samples.each do |sample|
        expect(sample.can_be_included_in_submission?).to be_falsey
      end
      sample = sample_manifest.samples.first
      sample.sample_metadata.supplier_name = 'new sample'
      expect(sample.can_be_included_in_submission?).to be_truthy
    end

    it 'knows when it can be included in submission if it was not registered through manifest' do
      sample = create :sample
      expect(sample.can_be_included_in_submission?).to be_truthy
    end
  end

  context 'Aker' do
    it 'can have many work orders' do
      work_order = create(:aker_work_order)
      expect(create(:sample, work_orders: [work_order]).work_orders).to include(work_order)
    end

    it 'can belong to a container' do
      container = create(:container)
      expect(create(:sample, container: container).container).to eq(container)
    end
  end
end
