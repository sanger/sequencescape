require 'rails_helper'

describe Billing::Field, billing: true do
  let(:field) { build :billing_field }

  it 'should have required attributes' do
    expect(field.valid?).to be true
  end

  it 'should know its value if it is static' do
    field.constant_value = 'TEST'
    expect(field.value).to eq 'TEST'
  end

  it 'should know its length' do
    expect(field.length).to eq 16
  end

  it 'should know its alignment' do
    expect(field.alignment).to eq '-'
    field.right_justified = true
    expect(field.alignment).to eq ''
  end

  it 'should know its value if it is dynamic' do
    billing_item = create :billing_item, units: '38'
    field.dynamic_attribute = :units
    expect(field.value(billing_item)).to eq '38'
  end
end
