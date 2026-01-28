# frozen_string_literal: true
require 'rails_helper'

# See additional related tests in spec/models/sample_spec.rb

RSpec.describe SampleAccessioningJob, type: :job do
  include AccessionV1ClientHelper

  let(:sample_metadata) { create(:sample_metadata_for_accessioning) }
  let(:sample) { create(:sample_for_accessioning_with_open_study, sample_metadata:) }
  let(:accessionable) { create(:accession_sample, sample:) }
  let(:job) { described_class.new(accessionable) }

  let(:logger) { instance_double(Logger, error: nil, debug: nil) }
  let(:exception_notifier) { class_double(ExceptionNotifier) }

  before do
    allow(Rails).to receive(:logger).and_return(logger)
    allow(ExceptionNotifier).to receive(:notify_exception)
  end

  describe '#perform' do
    # An accession sample status is created when the job is queued

    context 'when the submission fails validation' do
      let(:sample_metadata) { create(:sample_metadata_for_accessioning, sample_taxon_id: nil) }
      let(:enable_y25_705_notify_on_internal_accessioning_validation_failures) { false }

      before do
        create(:accession_sample_status, sample: sample, status: 'processing')

        if enable_y25_705_notify_on_internal_accessioning_validation_failures
          Flipper.enable(:y25_705_notify_on_internal_accessioning_validation_failures)
        else
          Flipper.disable(:y25_705_notify_on_internal_accessioning_validation_failures)
        end

        expect { job.perform }.to raise_error(Accession::InternalValidationError)
      end

      context 'when accessioning tag validation is enabled' do
        before do
          Flipper.disable(:y25_714_skip_accessioning_tag_validation)
        end

        it 'sets the accession sample status to failed' do
          sample_status = Accession::SampleStatus.where(sample:).first
          expect(sample_status).to have_attributes(
            status: 'failed',
            message: "Sample '#{sample.name}' cannot be accessioned: " \
                     'Sample does not have the required metadata: sample-taxon-id.'
          )
        end

        it 'logs the error' do
          expect(logger).to have_received(:error).with(
            "Sample '#{sample.name}' cannot be accessioned: " \
            'Sample does not have the required metadata: sample-taxon-id.'
          )
        end

        context 'when the y25_705_notify_on_internal_accessioning_validation_failures feature flag is disabled' do
          let(:enable_y25_705_notify_on_internal_accessioning_validation_failures) { false }

          it 'does not send an exception notification' do
            expect(ExceptionNotifier).not_to have_received(:notify_exception)
          end
        end

        context 'when the y25_705_notify_on_internal_accessioning_validation_failures feature flag is enabled' do
          let(:enable_y25_705_notify_on_internal_accessioning_validation_failures) { true }

          it 'notifies ExceptionNotifier' do
            sample_name = sample.name # 'Sample 1'
            expect(ExceptionNotifier).to have_received(:notify_exception).with(
              instance_of(Accession::InternalValidationError),
              data: {
                message: "SampleAccessioningJob failed for sample '#{sample_name}': " \
                         "Sample '#{sample_name}' cannot be accessioned: " \
                         'Sample does not have the required metadata: sample-taxon-id.',
                sample_name: sample_name,
                service_provider: 'ENA',
                user: nil
              }
            )
          end
        end
      end
    end

    context 'when accessioning tag validation is skipped' do
      before do
        Flipper.enable(:y25_714_skip_accessioning_tag_validation)
        allow(Accession::Submission).to receive(:client).and_return(
          stub_accession_client(:submit_and_fetch_accession_number, return_value: 'EGA00001000240')
        )
      end

      it 'allows the accessioning to proceed, not raising an error' do
        expect { job.perform }.not_to raise_error
      end

      it 'removes the latest accession sample status' do
        expect(Accession::SampleStatus.where(sample:)).not_to exist
      end
    end

    context 'when the submission is successful' do
      before do
        allow(Accession::Submission).to receive(:client).and_return(
          stub_accession_client(:submit_and_fetch_accession_number, return_value: 'EGA00001000240')
        )
      end

      it 'does not raise an error' do
        expect { job.perform }.not_to raise_error
      end

      it 'removes the latest accession sample status' do
        expect(Accession::SampleStatus.where(sample:)).not_to exist
      end
    end

    context 'when an exception is raised during submission' do
      let(:enable_y25_705_notify_on_external_accessioning_validation_failures) { false }

      before do
        create(:accession_sample_status, sample: sample, status: 'processing')
        allow(Accession::Submission).to receive(:client).and_return(
          stub_accession_client(:submit_and_fetch_accession_number,
                                raise_error:
                                Accession::ExternalValidationError.new('Failed to process accessioning response'))
        )

        if enable_y25_705_notify_on_external_accessioning_validation_failures
          Flipper.enable(:y25_705_notify_on_external_accessioning_validation_failures)
        else
          Flipper.disable(:y25_705_notify_on_external_accessioning_validation_failures)
        end

        expect { job.perform }.to raise_error(Accession::ExternalValidationError)
      end

      it 'logs the error' do
        expect(logger).to have_received(:error).with(
          "SampleAccessioningJob failed for sample '#{sample.name}': " \
          'Failed to process accessioning response'
        )
      end

      context 'when the y25_705_notify_on_external_accessioning_validation_failures feature flag is disabled' do
        let(:enable_y25_705_notify_on_external_accessioning_validation_failures) { false }

        it 'does not send an exception notification' do
          expect(ExceptionNotifier).not_to have_received(:notify_exception)
        end
      end

      context 'when the y25_705_notify_on_external_accessioning_validation_failures feature flag is enabled' do
        let(:enable_y25_705_notify_on_external_accessioning_validation_failures) { true }

        it 'notifies ExceptionNotifier' do
          expect(ExceptionNotifier).to have_received(:notify_exception).with(
            instance_of(Accession::ExternalValidationError),
            data: {
              message: "SampleAccessioningJob failed for sample '#{sample.name}': " \
                       'Failed to process accessioning response',
              sample_name: sample.name, # 'Sample 1',
              service_provider: 'ENA',
              user: nil
            }
          )
        end
      end
    end
  end

  describe '#reschedule_at' do
    it 'reschedules the job for the next day' do
      current_time = Time.zone.now
      expect(job.reschedule_at(current_time, 0)).to eq(current_time + 1.day)
    end
  end

  describe '#max_attempts' do
    it 'returns 3 as the maximum number of attempts' do
      expect(job.max_attempts).to eq(3)
    end
  end

  describe '#queue_name' do
    it 'returns the correct queue name' do
      expect(job.queue_name).to eq('sample_accessioning')
    end
  end

  describe '#enqueue' do
    before do
      job.enqueue(nil)
    end

    it 'creates an accession status for the sample' do
      expect(Accession::SampleStatus.where(sample:)).to exist
    end

    it 'sets the status to queued' do
      sample_status = Accession::SampleStatus.where(sample:).first
      expect(sample_status.status).to eq('queued')
    end
  end

  describe '#before' do
    before do
      job.before(nil)
    end

    it 'sets the status to in progress' do
      sample_status = Accession::SampleStatus.where(sample:).first
      expect(sample_status.status).to eq('processing')
    end
  end

  describe '#success' do
    before do
      create(:accession_sample_status, sample: sample, status: 'failed')
      create(:accession_sample_status, sample: sample, status: 'failed')
      job.success(nil)
    end

    it 'removes any existing accession sample statuses for the sample' do
      expect(Accession::SampleStatus.where(sample:)).not_to exist
    end
  end

  describe '#failure' do
    before do
      create(:accession_sample_status, sample: sample, status: 'failed')
      job.failure(nil)
    end

    it 'sets the status to aborted' do
      sample_status = Accession::SampleStatus.where(sample:).first
      expect(sample_status).to have_attributes(
        status: 'aborted',
        message: nil
      )
    end
  end
end
