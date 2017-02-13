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
end
