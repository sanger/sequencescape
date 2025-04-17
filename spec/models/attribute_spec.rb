# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Attributable::Attribute, type: :model do
  describe '#to_field_info' do
    let(:owner) { instance_double(RequestMetaData) }
    let(:name) { :test_attribute }
    let(:options) { { minimum: 1, maximum: 100, integer: true, default: 50, required: true } }
    let(:attribute) { described_class.new(owner, name, options) }

    it 'returns a FieldInfo object with the correct options' do # rubocop:disable RSpec/MultipleExpectations,RSpec/ExampleLength
      field_info = attribute.to_field_info

      expect(field_info).to be_a(FieldInfo)
      expect(field_info.display_name).to eq(attribute.display_name)
      expect(field_info.key).to eq(:test_attribute)
      expect(field_info.default_value).to eq(50)
      expect(field_info.kind).to eq(FieldInfo::NUMERIC)
      expect(field_info.required).to be(true)
      expect(field_info.min).to eq(1)
      expect(field_info.max).to eq(100)
      expect(field_info.step).to eq(1)
    end

    it 'handles attributes without a maximum value' do
      options.delete(:maximum)
      field_info = attribute.to_field_info

      expect(field_info.max).to be_nil
    end

    it 'handles float attributes with a step of 0.1' do
      options[:integer] = false
      options[:positive_float] = true
      field_info = attribute.to_field_info

      expect(field_info.step).to eq(0.1)
    end
  end
end
