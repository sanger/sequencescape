# frozen_string_literal: true
require 'rails_helper'

# See additional related tests in spec/models/sample_spec.rb

RSpec.describe SampleAccessioningJob do
  include AccessionV1ClientHelper

  let(:first_open_study) { create(:open_study, accession_number: 'ENA123') }
  let(:second_open_study) { create(:open_study, accession_number: 'ENA124') }
  let(:studies) { [first_open_study, second_open_study] }
  let(:sample_metadata) { create(:sample_metadata_for_accessioning) }
  let(:sample) { create(:sample_for_accessioning, sample_metadata:, studies:) }
  let(:accessionable) { create(:accession_sample, sample:) }
  let(:job) { described_class.new(accessionable) }

  let(:exception_notifier) { class_double(ExceptionNotifier) }

  before do
    allow(Rails.logger).to receive(:info).and_call_original
    allow(Rails.logger).to receive(:warn).and_call_original
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

        allow(job).to receive(:prevent_retries!)
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
            message: 'Cannot be accessioned: ' \
                     'Sample does not have the required metadata: sample taxon.'
          )
        end

        it 'logs the warning' do
          expect(Rails.logger).to have_received(:warn).with(
            "SampleAccessioningJob failed for sample '#{sample.name}': " \
            'Cannot be accessioned: ' \
            'Sample does not have the required metadata: sample taxon.'
          )
        end

        it 'calls prevent_retries!' do
          expect(job).to have_received(:prevent_retries!)
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
              instance_of(Accession::InvalidFieldsError),
              data: {
                message: "SampleAccessioningJob failed for sample '#{sample_name}': " \
                         'Cannot be accessioned: ' \
                         'Sample does not have the required metadata: sample-taxon-id.',
                sample_name: sample_name,
                study_names: "#{first_open_study.name}, #{second_open_study.name}",
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

      it 'logs the warning' do
        expect(Rails.logger).to have_received(:warn).with(
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
              study_names: "#{first_open_study.name}, #{second_open_study.name}",
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

  describe '#prevent_retries!' do
    let(:delayed_job) { instance_double(Delayed::Job, max_attempts: job.max_attempts, attempts: 1) }

    before do
      job.instance_variable_set(:@delayed_job, delayed_job)
      allow(delayed_job).to receive(:attempts=)
      allow(delayed_job).to receive(:save!)
    end

    it 'sets attempts to max_attempts + 1, to prevent retires' do # rubocop:disable RSpec/MultipleExpectations
      job.prevent_retries!

      expect(delayed_job).to have_received(:attempts=).with(job.max_attempts + 1)
      expect(delayed_job).to have_received(:save!)
    end
  end
end
