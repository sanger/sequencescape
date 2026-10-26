# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::Event do
  subject(:event) do
    described_class.new(api_operation: create(:api_operation),
                        task: 'reception',
                        event: 'completed')
  end

  it 'is valid with an operation, a task and an event' do
    expect(event).to be_valid
  end

  it 'requires an operation' do
    event.api_operation = nil
    expect(event).not_to be_valid
  end

  it 'requires a task' do
    event.task = nil
    expect(event).not_to be_valid
  end

  %w[completed failed].each do |name|
    it "accepts #{name}" do
      event.event = name
      expect(event).to be_valid
    end
  end

  it 'rejects an unknown event' do
    event.event = 'started'
    expect(event).not_to be_valid
  end

  it 'records when it happened' do
    event.save!
    expect(event.created_at).to be_present
  end
end
