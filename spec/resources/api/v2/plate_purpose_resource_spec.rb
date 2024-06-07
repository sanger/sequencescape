# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/plate_purpose_resource'

RSpec.describe Api::V2::PlatePurposeResource, type: :resource do
  # This test is different from the other resource tests because it will focus
  # on payloads, the custom resource attribute 'asset_shape', and plate 'size'.

  let(:purpose) { PlatePurpose.new } # New instance of PlatePurpose model
  let(:resource) { described_class.new(purpose, {}) } # Resource wrapping the instance
  let(:receive) { resource.replace_fields(payload[:data]) } # Simulate receiving payload
  let(:payload) { { data: { type: 'plate_purposes', attributes: attributes } } } # Payload to be received
  let(:purpose_name) { 'Example Purpose' }
  let(:plate_size) { 16 }
  let(:asset_shape_name) { 'ChromiumChip' }
  let(:asset_shape) { AssetShape.find_by(name: asset_shape_name) }

  context 'when asset_shape and size are specified in payload' do
    let(:attributes) { { name: purpose_name, size: plate_size, asset_shape: asset_shape_name } }

    # This creates a ChromiumChip 16-well plate purpose:
    # Example Purpose:
    #  size: 16
    #  asset_shape: ChromiumChip

    it 'sets the specified asset_shape and size' do
      receive
      expect(purpose.name).to eq purpose_name
      expect(purpose.asset_shape).to eq asset_shape # Association
      expect(purpose.asset_shape_id).to eq asset_shape.id # Foreign key
      expect(purpose.size).to eq plate_size
      expect(purpose).to be_valid
      expect(purpose.uuid).to be_present
    end
  end

  context 'when asset_shape and size are not specified in payload' do
    let(:attributes) { { name: purpose_name } }

    # This creates a Standard 96-well plate purpose (default).

    it 'sets the default asset_shape and size' do
      receive
      expect(purpose.name).to eq purpose_name
      expect(purpose.asset_shape).to eq AssetShape.default # Association
      expect(purpose.asset_shape_id).to eq AssetShape.default.id # Foreign key
      expect(purpose.size).to eq 96 # Default size
      expect(purpose).to be_valid
      expect(purpose.uuid).to be_present
    end
  end

  context 'when size is specified for Standard asset_shape' do
    let(:attributes) { { name: purpose_name, size: 384 } }

    # This creates a Standard 384-well plate purpose.

    it 'sets the specified size' do
      receive
      expect(purpose.asset_shape).to eq AssetShape.default # Association
      expect(purpose.asset_shape_id).to eq AssetShape.default.id # Foreign key
      expect(purpose.size).to eq 384
      expect(purpose.uuid).to be_present
    end
  end

  context 'when asset_shape is specified' do
    let(:attributes) { { name: purpose_name, asset_shape: asset_shape_name } }

    it 'sets the asset_shape' do
      receive
      expect(purpose.asset_shape).to eq asset_shape # Association
      expect(purpose.asset_shape_id).to eq asset_shape.id # Foreign key
    end
  end

  context 'when asset_shape is not specified' do
    let(:attributes) { { name: purpose_name } }

    it 'sets the default asset_shape' do
      receive
      expect(purpose.asset_shape).to eq AssetShape.default # Association
      expect(purpose.asset_shape_id).to eq AssetShape.default.id # Foreign key
    end
  end

  context 'when asset_shape is specified as Standard' do
    let(:attributes) { { name: purpose_name, asset_shape: 'Standard' } }

    it 'sets the default asset_shape' do
      receive
      expect(purpose.asset_shape).to eq AssetShape.default # Association
      expect(purpose.asset_shape_id).to eq AssetShape.default.id # Foreign key
    end
  end

  context 'when the specified asset_shape is not found' do
    let(:attributes) { { name: purpose_name, asset_shape: 'non-existing' } }

    it 'raises RecordNotFound error' do
      # Note the curly braces to set up an expecation for the error.
      expect { receive }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  context 'when size is specified' do
    let(:attributes) { { name: purpose_name, size: plate_size } }

    it 'sets the specified size' do
      receive
      expect(purpose.size).to eq plate_size
    end
  end

  context 'when size is not specified' do
    let(:attributes) { { name: purpose_name } }

    it 'sets the default size' do
      receive
      expect(purpose.size).to eq 96 # Default size
    end
  end

  context 'when attributes are missing' do
    let(:attributes) { { name: purpose_name } }

    it 'sets the defaults' do
      receive
      expect(purpose.stock_plate).to be false
      expect(purpose.cherrypickable_target).to be true
      expect(purpose.type).to eq 'PlatePurpose' # input_plate is false
    end
  end

  context 'when attributes are specified' do
    let(:attributes) { { name: purpose_name, stock_plate: true, cherrypickable_target: false, input_plate: true } }

    it 'sets the specified attributes' do
      receive
      expect(purpose.stock_plate).to be true
      expect(purpose.cherrypickable_target).to be false
      expect(purpose.type).to eq 'PlatePurpose::Input' # input_plate is true
    end
  end
end
