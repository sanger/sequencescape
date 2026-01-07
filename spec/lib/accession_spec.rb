# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Accession do
  describe '.accession_sample' do
    include AccessionV1ClientHelper

    before do
      create(:user, api_key: configatron.accession_local_key) # create contact user
    end

    context 'when accessioning is disabled', :accessioning_disabled do
      let(:event_user) { create(:user) }
      let(:sample_metadata) { create(:sample_metadata_for_accessioning) }
      let(:sample) { create(:sample_for_accessioning_with_open_study, sample_metadata:) }

      around do |example|
        Delayed::Worker.delay_jobs = false
        example.run
        Delayed::Worker.delay_jobs = true
      end

      it 'raises an exception if the sample cannot be accessioned' do
        expect { described_class.accession_sample(sample, event_user) }.to raise_error(AccessionService::AccessioningDisabledError)
      end

      it 'does not add an accession number if it fails' do
        begin
          described_class.accession_sample(sample, event_user)
        rescue AccessionService::AccessioningDisabledError
          # Ignore the error and continue execution
        end
        expect(sample.sample_metadata.sample_ebi_accession_number).to be_nil
      end
    end

    context 'when accessioning is enabled', :accessioning_enabled do
      let(:event_user) { create(:user) }

      around do |example|
        Delayed::Worker.delay_jobs = false
        example.run
        Delayed::Worker.delay_jobs = true
      end

      context 'when sample fails internal validation' do
        let(:sample_metadata) { create(:sample_metadata_for_accessioning, sample_taxon_id: nil) }
        let(:invalid_sample) { create(:sample_for_accessioning_with_open_study, sample_metadata:) }

        it 'raises an error with debug information' do # rubocop:disable RSpec/MultipleExpectations
          expect_accession = expect { described_class.accession_sample(invalid_sample, event_user) }
          expect_accession.to raise_error(AccessionService::AccessionValidationFailed) do |error|
            expect(error.message).to eq(
              "Sample '#{invalid_sample.name}' cannot be accessioned: " \
              'Sample does not have the required metadata: sample-taxon-id.'
            )
          end
        end
      end

      context 'when the sample has passed internal validations' do
        let(:sample_metadata) { create(:sample_metadata_for_accessioning) }
        let(:accessionable_sample) { create(:sample_for_accessioning_with_open_study, sample_metadata:) }

        context 'when the sample is linked to a study with accessioning disabled' do
          before do
            accessionable_sample.ena_study.enforce_accessioning = false

            described_class.accession_sample(accessionable_sample, event_user)
          end

          it 'does not receive an accession number' do
            expect(accessionable_sample.sample_metadata.sample_ebi_accession_number).to be_nil
          end
        end

        context 'when accessioning succeeds' do
          before do
            allow(Accession::Submission).to receive(:client).and_return(
              stub_accession_client(:submit_and_fetch_accession_number, return_value: 'EGA00001000240')
            )
            described_class.accession_sample(accessionable_sample, event_user)
          end

          it 'adds an accession number' do
            expect(accessionable_sample.sample_metadata.sample_ebi_accession_number).to be_present
          end

          # it also creates an event recording the accessioning, but this is tested in spec/lib/accession/sample_spec.rb
        end

        context 'when accessioning fails' do
          before do
            allow(Accession::Submission).to receive(:client).and_return(
              stub_accession_client(:submit_and_fetch_accession_number,
                                    raise_error: Accession::Error.new('Failed to process accessioning response'))
            )
          end

          it 'does not add an accession number' do
            accessionable_sample.save!

            expect(accessionable_sample.sample_metadata.sample_ebi_accession_number).to be_nil
          end

          it 'logs an error' do # rubocop:disable RSpec/MultipleExpectations
            allow(Rails.logger).to receive(:error).and_call_original

            expect { described_class.accession_sample(accessionable_sample, event_user) }.to raise_error(StandardError)

            expect(Rails.logger).to have_received(:error).with(
              "SampleAccessioningJob failed for sample '#{accessionable_sample.name}': " \
              'Failed to process accessioning response'
            )
          end

          it 'sends an exception notification' do # rubocop:disable RSpec/MultipleExpectations
            allow(ExceptionNotifier).to receive(:notify_exception)

            expect { described_class.accession_sample(accessionable_sample, event_user) }.to raise_error(StandardError)

            sample_name = accessionable_sample.name # 'Sample1'
            expect(ExceptionNotifier).to have_received(:notify_exception)
              .with(instance_of(Accession::Error),
                    data: { message: "SampleAccessioningJob failed for sample '#{sample_name}': " \
                                     'Failed to process accessioning response',
                            sample_name: sample_name,
                            service_provider: 'ENA' })
          end
        end
      end
    end
  end
end
