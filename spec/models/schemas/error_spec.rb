# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Schemas::Error do
  [
    Schemas::Source::NotFound,
    Schemas::LocalSource::MixedTypes,
    Schemas::JsonSchemaValidator::InvalidSchema,
    Schemas::Provider::UnsupportedType,
    Schemas::Provider::UnknownSource,
    Schemas::Provider::InvalidVersion
  ].each do |error|
    it "is the parent of #{error}" do
      expect(error).to be < described_class
    end
  end

  it 'is a standard error' do
    expect(described_class).to be < StandardError
  end
end
