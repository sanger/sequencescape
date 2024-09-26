# frozen_string_literal: true
require 'rails_helper'
RSpec.describe Heron::Factories::Concerns::Eventful, :heron_events do
  let(:my_test_class) do
    Class.new do
      include ActiveModel::Model
      include Heron::Factories::Concerns::Eventful

      def initialize(params)
        @params = params
      end
    end
  end

  let(:plate) { create :plate }
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
  let(:event) { { event: { event_type: event_type, subjects: subjects } } }

  describe '#build_events' do
    it 'returns a list of events' do
      instance = my_test_class.new({ events: [event] })
      expect(instance.build_events(plate).length).to eq(1)
    end
  end
end
