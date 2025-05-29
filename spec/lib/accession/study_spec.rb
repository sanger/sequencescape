# frozen_string_literal: true

require 'rails_helper'

MISSING_METADATA = {
  managed_study: 'sample-taxon-id, sample-common-name, gender, phenotype, and donor-id',
  open_study: 'sample-taxon-id and sample-common-name'
}.freeze
STUDY_TYPES = %i[open_study managed_study].freeze

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

  after do
    Delayed::Worker.delay_jobs = true
    configatron.accession_samples = true
    SampleManifestExcel.reset!
  end

  let!(:user) { create(:user, api_key: configatron.accession_local_key) }
  let(:accessionable_samples) { create_list(:sample_for_accessioning, 5) }
  let(:non_accessionable_samples) { create_list(:sample, 3) }

  STUDY_TYPES.each do |study_type|
    context "in a #{study_type}" do
      let(:missing_metadata_for_study) { MISSING_METADATA[study_type] }

      context 'when all samples in a study are accessionable' do
        let(:study) { create(study_type, accession_number: 'ENA123', samples: accessionable_samples) }

        before do
          study.accession_all_samples
          study.reload
        end

        it 'accessions only the samples with accession numbers' do
          expect(study.samples.count { |sample| sample.sample_metadata.sample_ebi_accession_number.present? }).to eq(
            accessionable_samples.count
          )
        end
      end

      context 'with studies missing accession numbers' do
        let(:study) { create(study_type, samples: create_list(:sample_for_accessioning, 5)) }

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

      context 'when some samples in a study are not accessionable' do
        let(:study) do
          create(study_type, accession_number: 'ENA123', samples: accessionable_samples + non_accessionable_samples)
        end

        before do
          study.accession_all_samples
          study.reload
        end

        it 'adds errors to the sample model' do
          expect(study.errors.full_messages).to eq(
            [
              "Accessionable is invalid for sample 'Sample6':" \
                " Sample does not have the required metadata: #{missing_metadata_for_study}.",
              "Accessionable is invalid for sample 'Sample7':" \
                " Sample does not have the required metadata: #{missing_metadata_for_study}.",
              "Accessionable is invalid for sample 'Sample8':" \
                " Sample does not have the required metadata: #{missing_metadata_for_study}."
            ]
          )
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

      context 'when none of the samples in a study are accessionable' do
        let(:study) { create(study_type, accession_number: 'ENA123', samples: non_accessionable_samples) }

        before do
          study.accession_all_samples
          study.reload
        end

        it 'adds errors to the sample model' do
          expect(study.errors.full_messages).to eq(
            [
              "Accessionable is invalid for sample 'Sample1':" \
                " Sample does not have the required metadata: #{missing_metadata_for_study}.",
              "Accessionable is invalid for sample 'Sample2':" \
                " Sample does not have the required metadata: #{missing_metadata_for_study}.",
              "Accessionable is invalid for sample 'Sample3':" \
                " Sample does not have the required metadata: #{missing_metadata_for_study}."
            ]
          )
        end

        it 'does not accession samples without accession numbers' do
          expect(study.samples.count { |sample| sample.sample_metadata.sample_ebi_accession_number.nil? }).to eq(
            non_accessionable_samples.count
          )
        end
      end
    end
  end
end
