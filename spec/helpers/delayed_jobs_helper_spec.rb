# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DelayedJobsHelper, type: :helper do
  let(:last_error) { nil }
  let(:job_name) { 'DefaultJob' }
  let(:locked_by) { nil }
  let(:failed) { false }
  let(:job) do
    instance_double(
      Delayed::Job,
      last_error: last_error,
      last_error?: last_error.present?,
      name: job_name,
      locked_by: locked_by,
      failed?: failed
    )
  end

  describe '#job_last_error' do
    context 'when the job has a last error' do
      let(:last_error) { "Error message\nBacktrace line 1\nBacktrace line 2" }

      it 'returns the first line of the last error' do
        expect(helper.job_last_error(job)).to eq('Error message')
      end
    end

    context 'when the job does not have a last error' do
      let(:last_error) { nil }

      it 'returns an empty string' do
        expect(helper.job_last_error(job)).to eq('')
      end
    end
  end

  describe '#job_type' do
    context 'when the job name matches "StudyReport"' do
      let(:job_name) { 'StudyReportJob' }

      it 'returns "generate study report"' do
        expect(helper.job_type(job)).to eq('generate study report')
      end
    end

    context 'when the job name matches "Submission"' do
      let(:job_name) { 'SubmissionJob' }

      it 'returns "process submission"' do
        expect(helper.job_type(job)).to eq('process submission ')
      end
    end

    context 'when the job name does not match any predefined types' do
      let(:job_name) { 'CustomJob' }

      it 'returns the job name' do
        expect(helper.job_type(job)).to eq('CustomJob')
      end
    end
  end

  describe '#job_status' do
    context 'when the job is locked by a worker' do
      let(:locked_by) { 'worker-1' }

      it 'returns "In progress"' do
        expect(helper.job_status(job)).to eq('In progress')
      end
    end

    context 'when the job has failed' do
      let(:failed) { true }

      it 'returns "Failed"' do
        expect(helper.job_status(job)).to eq('Failed')
      end
    end

    context 'when the job has a last error but is not failed or locked' do
      let(:last_error) { 'Some error occurred' }

      it 'returns "error"' do
        expect(helper.job_status(job)).to eq('error')
      end
    end

    context 'when the job is neither locked, failed, nor has a last error' do
      it 'returns "pending"' do
        expect(helper.job_status(job)).to eq('pending')
      end
    end
  end
end
