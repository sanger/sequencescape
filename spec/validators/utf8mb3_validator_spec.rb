# frozen_string_literal: true

require 'rails_helper'

describe Utf8mb3Validator do
  subject(:validated_instance) { validated_class.new(value) }

  let(:validated_class) do
    Struct.new(:validated) do
      include ActiveModel::Validations

      def self.name
        'name'
      end

      validates :validated, utf8mb3: true
    end
  end

  context 'when plain ASCII' do
    let(:value) { 'ASCII' }

    it { is_expected.to be_valid }
  end

  context 'when nil' do
    let(:value) { nil }

    it { is_expected.to be_valid }
  end

  context 'when a mix of 1,2 and 3 byte characters' do
    let(:value) { 'abcé✔' }

    it { is_expected.to be_valid }
  end

  context 'when using 4 byte characters' do
    let(:value) { 'abcé✔😋' }
    let(:expected_error) { 'Validated contains supplementary characters (eg. emoji), remove or replace them: 😋' }

    it { is_expected.not_to be_valid }

    it 'generates a useful error message' do
      validated_instance.valid?
      expect(validated_instance.errors.full_messages).to include(expected_error)
    end
  end
end
