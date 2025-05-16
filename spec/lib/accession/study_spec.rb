# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Study, :accession, type: :model do
  include MockAccession

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

  study_types = %i[open_study managed_study]

  study_types.each do |study_type|
    context "in a #{study_type}" do
      context 'when all samples in a study are accesionable' do
        let(:accessionable_samples) { create_list(:sample_for_accessioning, 5, :skip_accessioning) }
        let(:non_accessionable_samples) { create_list(:sample, 3) }
        let(:study) do
          create(study_type, accession_number: 'ENA123', samples: accessionable_samples + non_accessionable_samples)
        end

        before do
          study.accession_all_samples
          study.reload
        end

        it 'accessions only the samples with accession numbers' do
          expect(study.samples.count { |sample| sample.sample_metadata.sample_ebi_accession_number.present? }).to eq(
            accessionable_samples.count
          )
        end

        it 'does not accession samples without accession numbers' do
          expect(study.samples.count { |sample| sample.sample_metadata.sample_ebi_accession_number.nil? }).to eq(
            non_accessionable_samples.count
          )
        end
      end

      context 'with studies missing accession numbers' do
        let(:study) { create(study_type, samples: create_list(:sample_for_accessioning, 5, :skip_accessioning)) }

        before do
          # Verify expectation before running the method
          expect(study.samples.first).not_to receive(:accession)
          study.accession_all_samples
          study.reload
        end

        it 'does not accession any samples' do
          expect(study.samples).to be_all { |sample| sample.sample_metadata.sample_ebi_accession_number.nil? }
        end
      end
    end
  end
end
