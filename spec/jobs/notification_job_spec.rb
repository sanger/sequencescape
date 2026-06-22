# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotificationJob do
  let(:job) { described_class.new }
  let(:current_time) { Time.current }

  describe '#reschedule_at' do
    context 'when the first attempt has failed' do
      it 'retry after 10 minutes' do
        expect(job.reschedule_at(current_time, 1)).to eq(current_time + 10.minutes)
      end
    end

    context 'when the second attempt has failed' do
      it 'retry after 2 hours' do
        expect(job.reschedule_at(current_time, 2)).to eq(current_time + 2.hours)
      end
    end

    context 'when the third attempt has failed' do
      it 'retry after 21 hours' do
        expect(job.reschedule_at(current_time, 3)).to eq(current_time + 21.hours)
      end
    end
  end
end
