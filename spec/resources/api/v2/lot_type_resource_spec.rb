# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/lot_type_resource'

RSpec.describe Api::V2::LotTypeResource, type: :resource do
  let(:resource_model) { create :lot_type, template_class: template_class }
  let(:template_class) { 'TagLayoutTemplate' }
  subject(:resource) { described_class.new(resource_model, {}) }

  # Test attributes
  it 'works', :aggregate_failures do
    is_expected.to have_attribute :uuid
    is_expected.to have_attribute :name
    is_expected.to have_attribute :template_type
    is_expected.to_not have_updatable_field(:id)
    is_expected.to_not have_updatable_field(:uuid)
    is_expected.to_not have_updatable_field(:name)
    is_expected.to_not have_updatable_field(:template_type)
    is_expected.to have_one(:target_purpose).with_class_name('Purpose')
  end

  # Custom method tests
  # Add tests for any custom methods you've added.
  describe '#template_type' do
    subject { resource.template_type }

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
