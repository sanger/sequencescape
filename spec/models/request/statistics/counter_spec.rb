# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Request::Statistics::Counter do
  subject { described_class.new }

  # The counter isn't initialized with a hash but rather gets
  # set up in a loop. So we mimic the behaviour here
  before do
    subject['cancelled'] = 3
    subject['pending'] = 3
    subject['passed'] = 4
    subject['failed'] = 3
  end

  it 'calculates values for specific states', :aggregate_failures do
    # The total excludes cancelled requests
    expect(subject.total).to eq(10)
    expect(subject.progress).to eq(57)
    expect(subject.pending).to eq(3)
    expect(subject.failed).to eq(3)
    expect(subject.passed).to eq(4)
    expect(subject.cancelled).to eq(3)
    expect(subject.completed).to eq(7)
    expect(subject.started).to eq(0)
  end

  it '#states returns an array of statistics in a nice order' do
    # Cancelled requests are filtered out here.
    expect(subject.states).to eq([['pending', 3, 30], ['passed', 4, 40], ['failed', 3, 30]])
  end

  it '#states(except: ["pending"]) returns an array of statistics in a nice order with state missing' do
    # Cancelled requests are filtered out here.
    expect(subject.states(exclude: ['pending'])).to eq([['passed', 4, 40], ['failed', 3, 30]])
  end
end
