# frozen_string_literal: true
require 'rails_helper'

# See additional related tests in spec/models/sample_spec.rb

RSpec.describe SampleAccessioningJob, type: :job do
  include AccessionV1ClientHelper

  let(:contact_user) { create(:user, api_key: configatron.accession_local_key) }
  let(:sample_metadata) { create(:sample_metadata_for_accessioning) }
  let(:sample) { create(:sample_for_accessioning_with_open_study, sample_metadata:) }
  let(:accessionable) { create(:accession_sample, sample:) }
  let(:job) { described_class.new(accessionable) }

  let(:logger) { instance_double(Logger, error: nil) }
  let(:exception_notifier) { class_double(ExceptionNotifier) }

  before do
    allow(Rails).to receive(:logger).and_return(logger)
    allow(ExceptionNotifier).to receive(:notify_exception)
  end

  describe '#perform' do
    before do
      allow(described_class).to receive(:contact_user).and_return(contact_user)
    end

    context 'when the submission fails validation' do
      let(:sample_metadata) { create(:sample_metadata_for_accessioning, sample_taxon_id: nil) }

      before do
        # Create a submission that is invalid by not setting the user
        expect { job.perform }.to raise_error(JobFailed)
      end

      it 'logs the error' do
        expect(logger).to have_received(:error).with(
          "SampleAccessioningJob failed for sample '#{sample.name}': " \
          'Accessionable submission is invalid: ' \
          'Sample does not have the required metadata: sample-taxon-id.'
        )
      end

      it 'notifies ExceptionNotifier' do
        sample_name = sample.name # 'Sample 1'
        expect(ExceptionNotifier).to have_received(:notify_exception).with(
          instance_of(StandardError),
          data: {
            message: "SampleAccessioningJob failed for sample '#{sample_name}': " \
                     'Accessionable submission is invalid: ' \
                     'Sample does not have the required metadata: sample-taxon-id.',
            sample_name: sample_name,
            service_provider: 'ENA'
          }
        )
      end
    end

    context 'when the submission is successful' do
      before do
        allow(Accession::Submission).to receive(:client).and_return(
          stub_accession_client(:submit_and_fetch_accession_number, return_value: 'EGA00001000240')
        )
      end

      it 'does not raise an error' do
        expect { job.perform }.not_to raise_error # specifically JobFailed
      end
    end

    context 'when an exception is raised during submission' do
      before do
        allow(Accession::Submission).to receive(:client).and_return(
          stub_accession_client(:submit_and_fetch_accession_number,
                                raise_error: Accession::Error.new('Posting of accession submission failed'))
        )
        expect { job.perform }.to raise_error(JobFailed)
      end

      it 'logs the error' do
        expect(logger).to have_received(:error).with(
          "SampleAccessioningJob failed for sample '#{sample.name}': " \
          'Posting of accession submission failed'
        )
      end

      it 'notifies ExceptionNotifier' do
        expect(ExceptionNotifier).to have_received(:notify_exception).with(
          instance_of(Accession::Error),
          data: {
            message: "SampleAccessioningJob failed for sample '#{sample.name}': " \
                     'Posting of accession submission failed',
            sample_name: sample.name, # 'Sample 1',
            service_provider: 'ENA'
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
