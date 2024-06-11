# frozen_string_literal: true

require 'rails_helper'
require 'broadcast_event/lab_event'

RSpec.describe LabEvent do
  subject { build(:lab_event, user: build(:user)) }

  it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
    expect(subject).to respond_to :eventful
    expect(subject).to respond_to :user
  end

  it 'generates a broadcast event' do
    expect { subject.save! }.to change(BroadcastEvent, :count).by(1)
    expect(BroadcastEvent.last.seed).to eq subject
  end
end
