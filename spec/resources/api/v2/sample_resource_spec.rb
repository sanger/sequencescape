require 'rails_helper'
require './app/resources/api/v2/sample_resource'

RSpec.describe Api::V2::SampleResource, type: :resource do
  let(:sample) { create :sample }
  subject { described_class.new(sample, {}) }

  it 'works', :aggregate_failures do
    is_expected.to have_attribute :name
    is_expected.to have_attribute :sanger_sample_id
    is_expected.to have_attribute :uuid
  end

  it 'has sample metadata information' do
    is_expected.to have_one(:sample_metadata).with_class_name('Sample::Metadata')
  end
end
