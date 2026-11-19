# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::Task do
  let(:api_operation) { build(:api_operation) }

  describe '.for' do
    it 'gives the class of a task by its name' do
      expect(described_class.for('reception')).to eq(ApiOperation::Reception)
    end

    it 'has a task class for every task an operation type runs' do
      names = ApiOperation::TASKS.values.flatten.uniq
      expect(names.map { |name| described_class.for(name) })
        .to all(be < described_class)
    end

    it 'raises for a task it does not know' do
      expect { described_class.for('unknown') }.to raise_error(KeyError)
    end
  end

  it 'leaves #call to each task' do
    expect { described_class.new(api_operation).call }
      .to raise_error(NotImplementedError)
  end

  it 'gives a task its operation' do
    task_class = Class.new(described_class) do
      def call = api_operation
    end
    expect(task_class.new(api_operation).call).to be(api_operation)
  end
end
