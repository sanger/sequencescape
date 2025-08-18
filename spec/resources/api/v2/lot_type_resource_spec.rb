# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/lot_type_resource'

RSpec.describe Api::V2::LotTypeResource, type: :resource do
  subject(:resource) { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:lot_type, template_class:) }
  let(:template_class) { 'TagLayoutTemplate' }

  # Test attributes
  it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
    expect(resource).to have_attribute :uuid
    expect(resource).to have_attribute :name
    expect(resource).to have_attribute :template_type
    expect(resource).to have_readonly_attribute(:template_class)
    expect(resource).not_to have_updatable_field(:id)
    expect(resource).not_to have_updatable_field(:uuid)
    expect(resource).not_to have_updatable_field(:name)
    expect(resource).not_to have_updatable_field(:template_type)
    expect(resource).to have_a_write_once_has_one(:target_purpose).with_class_name('Purpose')

  end

  # Custom method tests
  # Add tests for any custom methods you've added.
  describe '#template_type' do
    subject(:template_type) { resource.template_type }

    context 'with a TagLayoutTemplate' do
      let(:template_class) { 'TagLayoutTemplate' }

      it { is_expected.to eq 'tag_layout_template' }
    end

    context 'with a TagLayoutTemplate' do
      let(:template_class) { 'PlateTemplate' }

      it { is_expected.to eq 'plate_template' }
    end

    context 'with a TagLayoutTemplate' do
      let(:template_class) { 'Tag2LayoutTemplate' }

      it { is_expected.to eq 'tag2_layout_template' }
    end
  end
end
