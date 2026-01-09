# frozen_string_literal: true

require 'rails_helper'

MISSING_METADATA = {
  managed_study: %w[sample-taxon-id sample-common-name gender phenotype donor-id].sort.to_sentence,
  open_study: %w[sample-taxon-id sample-common-name].sort.to_sentence
}.freeze
STUDY_TYPES = %i[open_study managed_study].freeze

RSpec.describe Study, :accession, :accessioning_enabled, type: :model do
  include AccessionV1ClientHelper

  let(:current_user) { create(:user) }
  let(:accession_number) { 'SAMPLE123456' }
  let(:accessionable_samples) { create_list(:sample_for_accessioning, 5) }
  let(:non_accessionable_samples) { create_list(:sample, 3) }

  before do
    Delayed::Worker.delay_jobs = false
    create(:user, api_key: configatron.accession_local_key)
    allow(Accession::Submission).to receive(:client).and_return(
      stub_accession_client(:submit_and_fetch_accession_number, return_value: accession_number)
    )
  end

  after do
    Delayed::Worker.delay_jobs = true
    SampleManifestExcel.reset!
  end

  STUDY_TYPES.each do |study_type|
    context "in a #{study_type}" do
      let(:missing_metadata_for_study) { MISSING_METADATA[study_type] }

      context 'when all samples in a study are accessionable' do
        let(:study) { create(study_type, accession_number: 'ENA123', samples: accessionable_samples) }

        before do
          study.accession_all_samples(current_user)
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
          expect(Accession).not_to receive(:accession_sample).with(study.samples.first, anything)
          study.accession_all_samples(current_user)
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
          study.accession_all_samples(current_user)
          study.reload
        end

        it 'adds errors to the sample model' do
          expect(study.errors.full_messages).to eq(
            [
              "Sample 'Sample6' cannot be accessioned: " \
              "Sample does not have the required metadata: #{missing_metadata_for_study}.",
              "Sample 'Sample7' cannot be accessioned: " \
              "Sample does not have the required metadata: #{missing_metadata_for_study}.",
              "Sample 'Sample8' cannot be accessioned: " \
              "Sample does not have the required metadata: #{missing_metadata_for_study}."
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
          study.accession_all_samples(current_user)
          study.reload
        end

        it 'adds errors to the sample model' do
          expect(study.errors.full_messages).to eq(
            [
              "Sample 'Sample1' cannot be accessioned: " \
              "Sample does not have the required metadata: #{missing_metadata_for_study}.",
              "Sample 'Sample2' cannot be accessioned: " \
              "Sample does not have the required metadata: #{missing_metadata_for_study}.",
              "Sample 'Sample3' cannot be accessioned: " \
              "Sample does not have the required metadata: #{missing_metadata_for_study}."
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
