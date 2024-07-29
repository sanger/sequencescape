# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/receptacle_resource'

RSpec.describe Api::V2::ReceptacleResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed :receptacle }

  # Test attributes
  it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
    expect(subject).to have_attribute :uuid
    expect(subject).to have_attribute :name
    expect(subject).to have_attribute :pcr_cycles
    expect(subject).to have_attribute :submit_for_sequencing
    expect(subject).to have_attribute :sub_pool
    expect(subject).to have_attribute :coverage
    expect(subject).to have_attribute :diluent_volume

    expect(subject).not_to have_updatable_field(:id)
    expect(subject).not_to have_updatable_field(:uuid)
    expect(subject).not_to have_updatable_field(:name)

    expect(subject).to have_updatable_field(:pcr_cycles)
    expect(subject).to have_updatable_field(:submit_for_sequencing)
    expect(subject).to have_updatable_field(:sub_pool)
    expect(subject).to have_updatable_field(:coverage)
    expect(subject).to have_updatable_field(:diluent_volume)

    expect(subject).to have_many(:qc_results).with_class_name('QcResult')
    expect(subject).to have_many(:samples).with_class_name('Sample')
    expect(subject).to have_many(:projects).with_class_name('Project')
    expect(subject).to have_many(:studies).with_class_name('Study')
    expect(subject).to have_one(:labware)
  end

  # Custom method tests
  # Add tests for any custom methods you've added.
  # describe '#labware_barcode' do
  #   subject { resource.labware_barcode }
  #   it { is_expected.to eq('ean13_barcode' => '', 'human_barcode' => '') }
  # end
end
