# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Heron::Factories::Event, :heron, :heron_events, type: :model do
  let(:plate) { create(:plate) }
  let(:subjects) do
    [
      build(
        :event_subject,
        role_type: BroadcastEvent::PlateCherrypicked::SOURCE_PLATES_ROLE_TYPE,
        subject_type: 'plate'
      ),
      build(:event_subject, role_type: BroadcastEvent::PlateCherrypicked::SAMPLE_ROLE_TYPE, subject_type: 'sample'),
      build(:event_subject, role_type: BroadcastEvent::PlateCherrypicked::ROBOT_ROLE_TYPE, subject_type: 'robot')
    ]
  end
  let(:event_type) { BroadcastEvent::PlateCherrypicked::EVENT_TYPE }
  let(:params) { { event: { event_type:, subjects: } } }

  it 'is valid with all relevant attributes' do
    event = described_class.new(params, plate)
    expect(event).to be_valid
  end

  it 'is not valid with wrong params' do
    event = described_class.new(params.except(:event), plate)
    expect(event).not_to be_valid
  end

  it 'is not valid without seed' do
    event = described_class.new(params, nil)
    expect(event).not_to be_valid
  end

  context 'with event type BroadcastEvent::PlateCherrypicked::EVENT_TYPE' do
    context 'when missing one of the required subjects' do
      let(:subjects) do
        [
          build(
            :event_subject,
            role_type: BroadcastEvent::PlateCherrypicked::SOURCE_PLATES_ROLE_TYPE,
            subject_type: 'plate'
          ),
          build(:event_subject, role_type: BroadcastEvent::PlateCherrypicked::SAMPLE_ROLE_TYPE, subject_type: 'sample')
        ]
      end

      it 'is not valid' do
        event = described_class.new(params, plate)
        expect(event).not_to be_valid
      end
    end
  end

  context 'when any other event type' do
    let(:event_type) { 'asdfasdf' }

    it 'is not valid' do
      event = described_class.new(params.except(:event), nil)
      expect(event).not_to be_valid
    end
  end

  describe '#save' do
    it 'persists the event if it is valid' do
      event = described_class.new(params, plate)
      expect { event.save }.to change(BroadcastEvent, :count).by(1)
    end

    it 'does not persist if missing any required info' do
      event = described_class.new(params, nil)
      expect { event.save }.not_to change(BroadcastEvent, :count)
    end
  end
end
