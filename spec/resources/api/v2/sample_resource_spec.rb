# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/sample_resource'

RSpec.describe Api::V2::SampleResource, type: :resource do
  subject { described_class.new(sample, {}) }

  let(:sample) { create :sample }

  it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
    expect(subject).to have_attribute :sanger_sample_id
    expect(subject).to have_attribute :uuid
  end

  it 'has sample metadata information' do
    expect(subject).to have_one(:sample_metadata).with_class_name('SampleMetadata')
  end
end
