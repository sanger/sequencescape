# frozen_string_literal: true
require 'rails_helper'

# See additional related tests in spec/models/sample_spec.rb

RSpec.describe SampleAccessioningJob, type: :job do
  let(:user) { create(:user, api_key: configatron.accession_local_key) }
  let(:sample) do
    create(:sample_for_accessioning_with_open_study, sample_metadata: create(:sample_metadata_for_accessioning))
  end
  let(:accessionable) { create(:accession_sample, sample:) }
  let(:submission) { build(:accession_submission, user:) }
  let(:job) { described_class.new(accessionable) }

  let(:logger) { instance_double(Logger, error: nil) }
  let(:exception_notifier) { class_double(ExceptionNotifier) }

  before do
    allow(Rails).to receive(:logger).and_return(logger)
    allow(ExceptionNotifier).to receive(:notify_exception)
  end

  describe '#perform' do
    context 'when the submission is successful' do
      before do
        allow(submission).to receive(:update_accession_number).and_return(true)
      end

      it 'does not raise an error' do
        expect { job.perform }.not_to raise_error
      end
    end

    context 'when the submission fails to update the accession number' do
      before do
        allow(submission).to receive(:update_accession_number).and_return(false)
        job.perform
      end

      it 'logs the error' do
        expect(logger).to have_received(:error).with(
          "SampleAccessioningJob failed for sample '#{sample.name}': " \
          'EBI failed to update accession number, data may be invalid'
        )
      end

      it 'notifies ExceptionNotifier' do
        expect(ExceptionNotifier).to have_received(:notify_exception).with(
          instance_of(AccessionService::AccessionServiceError),
          data: {
            cause_message: 'EBI failed to update accession number, data may be invalid',
            sample_name: sample.name, # 'Sample 1',
            service_provider: 'ENA'
          }
        )
      end
    end

    context 'when an exception is raised during submission' do
      let(:error) do
        AccessionService::AccessionServiceError.new(
          "SampleAccessioningJob failed for sample '#{sample.name}': " \
          'EBI failed to update accession number, data may be invalid'
        )
      end

      before do
        allow(submission).to receive(:post).and_raise(error)
        job.perform
      end

      it 'logs the error' do
        expect(logger).to have_received(:error).with(error.message)
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
end
