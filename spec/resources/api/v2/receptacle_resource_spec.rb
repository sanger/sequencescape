require 'rails_helper'
require './app/resources/api/v2/receptacle_resource'

RSpec.describe Api::V2::ReceptacleResource, type: :resource do
  let(:resource_model) { create :receptacle }
  subject(:resource) { described_class.new(resource_model, {}) }

  # Test attributes
  it { is_expected.to have_attribute :uuid }
  it { is_expected.to have_attribute :name }
  # it { is_expected.to have_attribute :labware_barcodes }
  # it { is_expected.to have_attribute :position }

  # Read only attributes (almost certainly id, uuid)
  it { is_expected.to_not have_updatable_field(:id) }
  it { is_expected.to_not have_updatable_field(:uuid) }
  it { is_expected.to_not have_updatable_field(:name) }
  # it { is_expected.to_not have_updatable_field(:position) }
  # it { is_expected.to_not have_updatable_field(:labware_barcode) }

  # Updatable fields
  # eg. it { is_expected.to have_updatable_field(:state) }

  # Filters
  # eg. it { is_expected.to filter(:order_type) }

  # Associations
  it { is_expected.to have_many(:samples).with_class_name('Sample') }
  it { is_expected.to have_many(:projects).with_class_name('Project') }
  it { is_expected.to have_many(:studies).with_class_name('Study') }

  # Custom method tests
  # Add tests for any custom methods you've added.
  # describe '#labware_barcode' do
  #   subject { resource.labware_barcode }
  #   it { is_expected.to eq('ean13_barcode' => '', 'human_barcode' => '') }
  # end
end
