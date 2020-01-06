# frozen_string_literal: true

require 'rails_helper'

describe Billing::FieldsList, billing: true do
  let!(:fields_attributes) { YAML.load_file(Rails.root.join('spec/data/billing/fields.yml')).with_indifferent_access }
  let(:fields_list) { described_class.new(fields_attributes) }

  it 'creates correct fields' do
    expect(fields_list.count).to eq 18
    expect(fields_list.all?(&:valid?)).to eq true
  end

  it 'knows the next field and number of spaces to next field' do
    field = fields_list.find { |f| f.name == 'dim_3' }
    next_field = fields_list.find { |f| f.name == 'dim_6' }
    expect(fields_list.next_field(field)).to eq next_field
    expect(fields_list.spaces_to_next_field(field)).to eq 50
  end
end
