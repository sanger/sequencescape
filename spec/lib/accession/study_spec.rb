# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Study, type: :model, accession: true do
  include MockAccession

  context 'accession all samples in study' do
    before do
      Delayed::Worker.delay_jobs = false
      configatron.accession_samples = true
      Accession.configure do |config|
        config.folder = File.join('spec', 'data', 'accession')
        config.load!
      end
      allow(Accession::Request).to receive(:post).and_return(build(:successful_accession_response))
    end

    let!(:user) { create(:user, api_key: configatron.accession_local_key) }

    after do
      Delayed::Worker.delay_jobs = true
      configatron.accession_samples = true
      SampleManifestExcel.reset!
    end

    it 'accessions all of the samples that are accessionable' do
      open_study =
        create(
          :open_study,
          accession_number: 'ENA123',
          samples: create_list(:sample_for_accessioning, 5) + create_list(:sample, 3)
        )
      open_study.accession_all_samples
      open_study.reload
      expect(open_study.samples.count { |sample| sample.sample_metadata.sample_ebi_accession_number.present? }).to eq(5)
      expect(open_study.samples.count { |sample| sample.sample_metadata.sample_ebi_accession_number.nil? }).to eq(3)

      managed_study =
        create(
          :managed_study,
          accession_number: 'ENA123',
          samples: create_list(:sample_for_accessioning, 5) + create_list(:sample, 3)
        )
      managed_study.accession_all_samples
      managed_study.reload
      expect(
        managed_study.samples.count { |sample| sample.sample_metadata.sample_ebi_accession_number.present? }
      ).to eq(5)
      expect(managed_study.samples.count { |sample| sample.sample_metadata.sample_ebi_accession_number.nil? }).to eq(3)
    end

    it 'will not attempt to accession any samples belonging to a study that does not have an accession number' do
      open_study = create(:open_study, samples: create_list(:sample_for_accessioning, 5))
      expect(open_study.samples.first).not_to receive(:accession)
      open_study.accession_all_samples
      open_study.reload
      expect(open_study.samples).to be_all { |sample| sample.sample_metadata.sample_ebi_accession_number.nil? }

      managed_study = create(:managed_study, samples: create_list(:sample_for_accessioning, 5))
      expect(managed_study.samples.first).not_to receive(:accession)
      managed_study.accession_all_samples
      managed_study.reload
      expect(managed_study.samples).to be_all { |sample| sample.sample_metadata.sample_ebi_accession_number.nil? }
    end
  end
end
