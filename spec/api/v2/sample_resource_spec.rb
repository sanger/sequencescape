require 'rails_helper'
require './app/resources/api/v2/sample_resource'

RSpec.describe Api::V2::SampleResource, type: :resource do
  let(:sample) { create :sample }
  subject { described_class.new(sample, {}) }

  it { is_expected.to have_attribute :sanger_sample_id }
end
