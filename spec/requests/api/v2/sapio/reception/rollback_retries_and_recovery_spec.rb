# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/sapio_reception_shared_context'

# Sapio reception from end to end, when a run goes wrong: an unexpected error
# part way through creation keeps nothing, a transient error is retried, and
# a reception already committed isn't run again. The faults come from
# AliquotFactory, which creation runs after it has created the labware and
# samples. How these specs work:
# spec/shared_contexts/sapio_reception_shared_context.rb
describe 'Sapio reception rollback, retries and recovery',
         :sapio_operations_endpoint_enabled, :sapio_reception_enabled do
  include_context 'with Sapio reception'

  let(:aliquot_factory) { ApiOperation::Reception::Creation::AliquotFactory }
  let(:request) do
    reception_request(plate('SAPIO-PLATE-1', 'A1' => sample('SAPIO-1-1'),
                                             'B1' => sample('SAPIO-1-2')))
  end
  let(:operation) do
    ApiOperation.find_by!(external_id: request.dig(:request, :external_id))
  end

  context 'when creation raises an unexpected error part way' do
    let(:error) { NoMethodError.new("undefined method 'name' for nil") }
    # The labware and samples there were when the error came
    let(:counts_at_the_error) { [] }

    before do
      allow(aliquot_factory).to receive(:new) do
        counts_at_the_error.push(Labware.count, Sample.count)
        raise error
      end
      allow(ExceptionNotifier).to receive(:notify_exception)
      post_and_process(request)
    end

    it 'had created the labware and samples when the error came' do
      expect(counts_at_the_error).to eq([1, 2])
    end

    it 'keeps none of them' do
      expect([Labware.count, Sample.count]).to eq([0, 0])
    end

    it 'fails the reception, saying PSD has been notified' do
      expect([operation.status, operation.error_details]).to eq(
        ['reception_failed',
         { 'task' => 'reception',
           'errors' => [{ 'pointer' => '',
                          'detail' => 'Reception could not be completed ' \
                                      'because of an error in ' \
                                      'Sequencescape; PSD has been ' \
                                      'notified' }] }]
      )
    end

    it 'notifies PSD of the error' do
      expect(ExceptionNotifier).to have_received(:notify_exception)
        .with(error, data: { api_operation_id: operation.id,
                             task: 'reception' })
    end

    it 'records the run of the reception' do
      expect(operation.events.pluck(:task, :outcome))
        .to eq([%w[reception started], %w[reception failed]])
    end
  end

  context 'when creation raises a transient error, then succeeds' do
    # The labware and samples there were when the error came
    let(:counts_at_the_error) { [] }

    before do
      runs = 0
      allow(aliquot_factory).to receive(:new).and_wrap_original do |new, *args|
        runs += 1
        if runs == 1
          counts_at_the_error.push(Labware.count, Sample.count)
          raise ActiveRecord::Deadlocked
        end

        new.call(*args)
      end
      post_as_integration_hub(request)
      # The first run fails, so Delayed Job runs the job again later
      Delayed::Worker.new.work_off
    end

    it 'leaves the operation queued after the first run' do
      expect([operation.status, operation.events.pluck(:outcome)])
        .to eq(['queued', %w[started]])
    end

    it 'keeps nothing from the first run' do
      expect([counts_at_the_error, Labware.count, Sample.count])
        .to eq([[1, 2], 0, 0])
    end

    context 'when Delayed Job runs the job again' do
      before do
        travel_to(Delayed::Job.sole.run_at + 1.second) { work_off_jobs }
      end

      it 'completes the reception' do
        expect(operation.status).to eq('reception_completed')
      end

      it 'creates the labware, samples and aliquots once' do
        expect([Labware.count, Sample.count, Aliquot.count]).to eq([1, 2, 2])
      end

      it 'records each run' do
        expect(operation.events.pluck(:outcome))
          .to eq(%w[started started completed])
      end
    end
  end

  # As when a worker stops after the reception commits but before Delayed
  # Job deletes the job, so the job runs again
  context 'when the job runs again after the reception has completed' do
    let(:job_again) do
      Delayed::Job.enqueue(ApiOperation::CoordinatorJob.new(operation.id))
    end

    before do
      post_and_process(request)
      allow(ApiOperation::Reception).to receive(:new).and_call_original
      job_again
      work_off_jobs
    end

    it 'runs the job' do
      expect(Delayed::Job.exists?(job_again.id)).to be(false)
    end

    it 'does not run the reception again' do
      expect(ApiOperation::Reception).not_to have_received(:new)
    end

    it 'leaves the reception completed' do
      expect(operation.status).to eq('reception_completed')
    end

    it 'records no more events' do
      expect(operation.events.pluck(:outcome)).to eq(%w[started completed])
    end
  end
end
