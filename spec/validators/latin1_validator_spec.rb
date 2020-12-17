# frozen_string_literal: true

require 'rails_helper'

describe Latin1Validator do
  subject(:validated_instance) { validated_class.new(value) }

  let(:validated_class) do
    Struct.new(:validated) do
      include ActiveModel::Validations

      def self.name
        'name'
      end

      validates :validated, latin1: true
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

  context 'when latin1 supported special characters' do
    let(:value) { 'Somatic mutation in Primary Sjögren’s Syndrome' }

    it { is_expected.to be_valid }
  end

  context 'when containing chracters not supported by latin1' do
    let(:value) { 'hЗllo' }
    let(:expected_error) do
      'Validated contains unsupported characters (non-latin characters), remove or replace them: З'
    end

    it { is_expected.not_to be_valid }

    it 'generates a useful error message' do
      validated_instance.valid?
      expect(validated_instance.errors.full_messages).to include(expected_error)
    end
  end
end
