require 'rails_helper'

RSpec.describe Study, type: :model, accession: true do
  include MockAccession

  context 'accession all samples in study' do
    before(:each) do
      Delayed::Worker.delay_jobs = false
      configatron.accession_samples = true
      Accession.configure do |config|
        config.folder = File.join('spec', 'data', 'accession')
        config.load!
      end
      allow(Accession::Request).to receive(:post).and_return(build(:successful_accession_response))
    end

    let!(:user) { create(:user, api_key: configatron.accession_local_key) }

    it 'accessions all of the samples that are accessionable' do
      open_study = create(:open_study, accession_number: 'ENA123', samples: create_list(:sample_for_accessioning, 5) + create_list(:sample, 3))
      open_study.accession_all_samples
      open_study.reload
      expect(open_study.samples.select { |sample| sample.sample_metadata.sample_ebi_accession_number.present? }.count).to eq(5)
      expect(open_study.samples.select { |sample| sample.sample_metadata.sample_ebi_accession_number.nil? }.count).to eq(3)

      managed_study = create(:managed_study, accession_number: 'ENA123', samples: create_list(:sample_for_accessioning, 5) + create_list(:sample, 3))
      managed_study.accession_all_samples
      managed_study.reload
      expect(managed_study.samples.select { |sample| sample.sample_metadata.sample_ebi_accession_number.present? }.count).to eq(5)
      expect(managed_study.samples.select { |sample| sample.sample_metadata.sample_ebi_accession_number.nil? }.count).to eq(3)
    end

    it 'will not attempt to accession any samples belonging to a study that does not have an accession number' do
      open_study = create(:open_study, samples: create_list(:sample_for_accessioning, 5))
      expect(open_study.samples.first).to_not receive(:accession)
      open_study.accession_all_samples
      open_study.reload
      expect(open_study.samples.all? { |sample| sample.sample_metadata.sample_ebi_accession_number.nil? }).to be_truthy

      managed_study = create(:managed_study, samples: create_list(:sample_for_accessioning, 5))
      expect(managed_study.samples.first).to_not receive(:accession)
      managed_study.accession_all_samples
      managed_study.reload
      expect(managed_study.samples.all? { |sample| sample.sample_metadata.sample_ebi_accession_number.nil? }).to be_truthy
    end

    after(:each) do
      Delayed::Worker.delay_jobs = true
      configatron.accession_samples = true
      SampleManifestExcel.reset!
    end
  end
end
