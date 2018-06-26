# frozen_string_literal: true

require 'rails_helper'
require 'broadcast_event/lab_event'

RSpec.describe LabEvent do
  subject { build :lab_event, user: build(:user) }

  it 'works', :aggregate_failures do
    is_expected.to respond_to :eventful
    is_expected.to respond_to :user
  end

  it 'generates a broadcast event' do
    expect { subject.save! }.to change { BroadcastEvent.count }.by(1)
    expect(BroadcastEvent.last.seed).to eq subject
  end
end
