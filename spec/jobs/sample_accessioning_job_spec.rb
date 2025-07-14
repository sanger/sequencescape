# frozen_string_literal: true
require 'rails_helper'

RSpec.describe SampleAccessioningJob, type: :job do
  let(:accessionable) { create(:sample_with_sanger_sample_id) }
  let(:user) { instance_double(User, id: 1) }
  let(:submission) { instance_double(Accession::Submission) }
  let(:job) { described_class.new(accessionable) }

  let(:logger) { instance_double(Logger, error: nil) }
  let(:exception_notifier) { class_double(ExceptionNotifier, notify_exception: nil) }

  before do
    allow(User).to receive(:find_by).with(api_key: configatron.accession_local_key).and_return(user)
    allow(Accession::Submission).to receive(:new).with(user, accessionable).and_return(submission)

    allow(Rails).to receive(:logger).and_return(logger)
    allow(ExceptionNotifier).to receive(:notify_exception)
  end

  describe '#perform' do
    context 'when the submission is successful' do
      before do
        allow(submission).to receive(:post)
        allow(submission).to receive(:update_accession_number).and_return(true)
      end

      it 'does not raise an error' do
        expect { job.perform }.not_to raise_error
      end
    end

    context 'when the submission fails to update the accession number' do
      before do
        allow(submission).to receive(:post)
        allow(submission).to receive(:update_accession_number).and_return(false)
        job.perform
      end

      it 'logs the error' do
        expect(logger).to have_received(:error).with(
          "Error performing SampleAccessioningJob for sample '#{accessionable.sanger_sample_id}': " \
          'EBI failed to update accession number, data may be invalid'
        )
      end

      it 'notifies ExceptionNotifier' do
        expect(ExceptionNotifier).to have_received(:notify_exception).with(
          instance_of(AccessionService::AccessionServiceError),
          data: {
            message: "Error performing SampleAccessioningJob for sample '#{accessionable.sanger_sample_id}': " \
                     'EBI failed to update accession number, data may be invalid'
          }
        )
      end
    end

    context 'when an exception is raised during submission' do
      let(:error) { AccessionService::AccessionServiceError.new('Something went wrong') }

      before do
        allow(submission).to receive(:post).and_raise(error)
        job.perform
      end

      it 'logs the error' do
        expect(logger).to have_received(:error).with(
          "Error performing SampleAccessioningJob for sample '#{accessionable.sanger_sample_id}': #{error.message}"
        )
      end

      it 'notifies ExceptionNotifier' do
        expect(ExceptionNotifier).to have_received(:notify_exception).with(
          error,
          data: {
            message: "Error performing SampleAccessioningJob for sample '#{accessionable.sanger_sample_id}': " \
                     "#{error.message}"
          }
        )
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
