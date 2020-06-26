# frozen_string_literal: true

require 'rails_helper'

describe Billing::Field, billing: true do
  let(:field) { build :billing_field }

  it 'has required attributes' do
    expect(field.valid?).to be true
  end

  it 'knows its value if it is static' do
    field.constant_value = 'TEST'
    expect(field.value).to eq 'TEST'
  end

  it 'knows its length' do # rubocop:todo RSpec/AggregateExamples
    expect(field.length).to eq 16
  end

  it 'knows its alignment' do
    expect(field.alignment).to eq :ljust
    field.right_justified = true
    expect(field.alignment).to eq :rjust
  end

  it 'knows its value if it is dynamic' do
    billing_item = create :billing_item, units: '38'
    field.dynamic_attribute = :units
    expect(field.value(billing_item)).to eq '38'
  end
end
