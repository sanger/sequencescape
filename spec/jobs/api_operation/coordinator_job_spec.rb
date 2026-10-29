# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::CoordinatorJob do
  let(:api_operation) { create(:api_operation) }

  def perform
    described_class.new(api_operation.id).perform
  end

  describe '#reschedule_at' do
    let(:job) { described_class.new(api_operation.id) }
    let(:now) { Time.zone.local(2026, 10, 29, 12) }

    def wait(attempts)
      job.reschedule_at(now, attempts) - now
    end

    it 'waits about a minute after the first failed run' do
      expect(wait(1)).to be_within(1).of(56.5)
    end

    it 'doubles the wait after each failed run' do
      expect((2..8).map { wait(it) / wait(it - 1) }).to all(eq(2))
    end

    it 'waits about 2 hours after the last failed run it retries' do
      expect(wait(described_class::RETRIES)).to be_within(60).of(2.hours)
    end

    it 'spreads the retries over the retry window' do
      expect((1..described_class::RETRIES).sum { wait(it) })
        .to be_within(1).of(described_class::RETRY_WINDOW)
    end
  end

  describe '#max_attempts' do
    it 'allows the first run and each retry' do
      expect(described_class.new(api_operation.id).max_attempts)
        .to eq(described_class::RETRIES + 1)
    end
  end

  context 'when reception is disabled', :sapio_reception_disabled do
    it 'logs that the operation is ready for processing' do
      allow(Rails.logger).to receive(:info)
      perform
      expect(Rails.logger).to have_received(:info)
        .with("ApiOperation #{api_operation.uuid} is ready for processing")
    end

    it 'does not run the reception' do
      allow(ApiOperation::Reception).to receive(:new)
      perform
      expect(ApiOperation::Reception).not_to have_received(:new)
    end

    it 'leaves the operation queued' do
      perform
      expect(api_operation.reload.status).to eq('queued')
    end
  end

  context 'when reception is enabled', :sapio_reception_enabled do
    let(:errors) { [] }
    let(:reception) { instance_double(ApiOperation::Reception, call: errors) }

    before do
      allow(ApiOperation::Reception).to receive(:new).and_return(reception)
    end

    it 'runs the reception for the operation' do
      perform
      expect(ApiOperation::Reception).to have_received(:new)
        .with(api_operation)
    end

    it 'records the reception as completed' do
      perform
      expect(api_operation.reload.status).to eq('reception_completed')
    end

    it 'adds a started event, then a completed one' do
      perform
      expect(api_operation.events.pluck(:task, :outcome))
        .to eq([%w[reception started], %w[reception completed]])
    end

    context 'when the reception runs' do
      let(:outcomes_seen) { [] }

      before do
        allow(reception).to receive(:call) do
          outcomes_seen.concat(api_operation.events.pluck(:outcome))
          []
        end
      end

      it 'has recorded its start' do
        perform
        expect(outcomes_seen).to eq(%w[started])
      end
    end

    context 'when the reception finds errors' do
      let(:errors) { [{ pointer: '/labware/0', detail: 'Barcode in use' }] }

      it 'records the reception as failed' do
        perform
        expect(api_operation.reload.status).to eq('reception_failed')
      end

      it 'adds a started event, then a failed one' do
        perform
        expect(api_operation.events.pluck(:outcome))
          .to eq(%w[started failed])
      end

      it 'stores the errors' do
        perform
        expect(api_operation.reload.error_details).to eq(
          'task' => 'reception',
          'errors' => [{ 'pointer' => '/labware/0',
                         'detail' => 'Barcode in use' }]
        )
      end
    end

    described_class::TRANSIENT_ERRORS.each do |error|
      context "when the reception raises #{error}" do
        before { allow(reception).to receive(:call).and_raise(error) }

        it 'passes the error on, so Delayed Job runs the job again' do
          expect { perform }.to raise_error(error)
        end

        it 'leaves the operation queued' do
          suppress(error) { perform }
          expect(api_operation.reload.status).to eq('queued')
        end
      end
    end

    context 'when the reception raises a transient error' do
      before do
        allow(reception).to receive(:call).and_raise(ActiveRecord::Deadlocked)
      end

      it 'keeps the started event, with no outcome after it' do
        suppress(ActiveRecord::Deadlocked) { perform }
        expect(api_operation.events.pluck(:outcome)).to eq(%w[started])
      end

      it 'adds a started event for each run' do
        suppress(ActiveRecord::Deadlocked) { perform }
        allow(reception).to receive(:call).and_return([])
        perform
        expect(api_operation.events.pluck(:outcome))
          .to eq(%w[started started completed])
      end

      context 'when a Delayed Job worker runs the job' do
        let(:job) do
          Delayed::Job.enqueue(described_class.new(api_operation.id))
        end

        before do
          travel_to(Time.zone.local(2026, 10, 29, 12))
          Delayed::Worker.new.run(job)
        end

        it 'records the failed run' do
          expect(job.reload.attempts).to eq(1)
        end

        it 'runs the job again about a minute later' do
          expect(job.reload.run_at)
            .to be_within(2.seconds).of(56.seconds.from_now)
        end
      end
    end

    context 'when the reception raises any other error' do
      let(:error) { NoMethodError.new("undefined method 'name' for nil") }

      before do
        allow(reception).to receive(:call) do
          create(:sample)
          raise error
        end
        allow(ExceptionNotifier).to receive(:notify_exception)
      end

      it 'does not pass the error on, so Delayed Job does not run it again' do
        expect { perform }.not_to raise_error
      end

      it 'records the reception as failed' do
        perform
        expect(api_operation.reload.status).to eq('reception_failed')
      end

      it 'stores an error that says PSD has been notified' do
        perform
        expect(api_operation.reload.error_details).to eq(
          'task' => 'reception',
          'errors' => [{ 'pointer' => '',
                         'detail' => 'Reception could not be completed ' \
                                     'because of an error in Sequencescape; ' \
                                     'PSD has been notified' }]
        )
      end

      it 'notifies PSD of the error, without the payload' do
        perform
        expect(ExceptionNotifier).to have_received(:notify_exception)
          .with(error, data: { api_operation_id: api_operation.id,
                               task: 'reception' })
      end

      it 'keeps nothing the reception created' do
        expect { perform }.not_to change(Sample, :count)
      end

      it 'adds a started event, then a failed one' do
        perform
        expect(api_operation.events.pluck(:outcome))
          .to eq(%w[started failed])
      end
    end

    # A model rule that reception's checks don't mirror
    context 'when a record the reception saves is invalid' do
      let(:sample) { Sample.new.tap { it.errors.add(:name, :taken) } }
      let(:error) { ActiveRecord::RecordInvalid.new(sample) }

      before do
        allow(reception).to receive(:call).and_raise(error)
        allow(ExceptionNotifier).to receive(:notify_exception)
      end

      it 'stores an error with the validation message' do
        perform
        expect(api_operation.reload.error_details['errors']).to eq(
          [{ 'pointer' => '',
             'detail' => 'Reception could not be completed: Validation ' \
                         'failed: Name has already been taken; PSD has ' \
                         'been notified' }]
        )
      end

      it 'notifies PSD, as reception should have found it' do
        perform
        expect(ExceptionNotifier).to have_received(:notify_exception)
          .with(error, anything)
      end
    end

    context 'when recording the failure raises a transient error' do
      before do
        allow(ApiOperation).to receive(:find).and_return(api_operation)
        allow(reception).to receive(:call).and_raise(NoMethodError)
        allow(ExceptionNotifier).to receive(:notify_exception)
        allow(api_operation).to receive(:fail_task!)
          .and_raise(ActiveRecord::Deadlocked)
      end

      it 'passes it on, so Delayed Job runs the job again' do
        expect { perform }.to raise_error(ActiveRecord::Deadlocked)
      end

      it 'has notified PSD of the first error' do
        suppress(ActiveRecord::Deadlocked) { perform }
        expect(ExceptionNotifier).to have_received(:notify_exception)
          .with(an_instance_of(NoMethodError), anything)
      end
    end

    # Another worker completes the reception after this run's reception
    # raised, but before this run locks the operation to record the failure
    context 'when another run completes the reception after this one raises' do
      before do
        allow(reception).to receive(:call).and_raise(NoMethodError)
        allow(ExceptionNotifier).to receive(:notify_exception) do
          ApiOperation.find_by(id: api_operation.id).complete_task!('reception')
        end
      end

      it "keeps the other run's outcome" do
        perform
        expect(api_operation.reload.status).to eq('reception_completed')
      end
    end

    context 'when the reception has already completed' do
      before { api_operation.complete_task!('reception') }

      it 'does not run it again' do
        perform
        expect(ApiOperation::Reception).not_to have_received(:new)
      end

      it 'adds no event' do
        expect { perform }.not_to(change { api_operation.events.count })
      end
    end

    # Another worker completes the reception after this run has recorded its
    # start, but before this run locks the operation to run it
    context 'when another run completes the reception after this one starts' do
      before do
        allow(ApiOperation).to receive(:find).and_return(api_operation)
        allow(api_operation).to receive(:start_task!)
          .and_wrap_original do |start_task, task|
            start_task.call(task)
            ApiOperation.find_by(id: api_operation.id).complete_task!(task)
          end
      end

      it 'does not run it' do
        perform
        expect(ApiOperation::Reception).not_to have_received(:new)
      end
    end

    context 'when the reception has already failed' do
      before { api_operation.fail_task!('reception', [{ detail: 'Failed' }]) }

      it 'does not run it again' do
        perform
        expect(ApiOperation::Reception).not_to have_received(:new)
      end
    end

    it 'runs the reception once when the job runs twice' do
      2.times { perform }
      expect(reception).to have_received(:call).once
    end

    it 'locks the operation before running its task' do
      allow(ApiOperation).to receive(:find).and_return(api_operation)
      allow(api_operation).to receive(:lock!).and_call_original
      perform
      expect(api_operation).to have_received(:lock!).at_least(:once)
    end
  end
end
