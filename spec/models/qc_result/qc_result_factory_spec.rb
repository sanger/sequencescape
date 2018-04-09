# frozen_string_literal: true

require 'rails_helper'

RSpec.describe QcResultFactory, type: :model, qc_result: true do
  describe 'multiple resources' do
    let(:asset_1) { attributes_for(:qc_result).merge(uuid: create(:asset).uuid) }
    let(:asset_2) { attributes_for(:qc_result).merge(uuid: create(:asset).uuid) }
    let(:asset_3) { attributes_for(:qc_result).merge(uuid: create(:asset).uuid) }
    let(:asset_invalid_uuid) { attributes_for(:qc_result) }
    let(:asset_invalid_key) { attributes_for(:qc_result).except(:key).merge(uuid: create(:asset).uuid) }

    it 'creates a resource for each item passed' do
      factory = QcResultFactory.new([asset_1, asset_2, asset_3])
      expect(factory.resources.count).to eq(3)
    end

    it '#save saves all of the resources if they are valid' do
      factory = QcResultFactory.new([asset_1, asset_2, asset_3])
      expect(factory).to be_valid
      expect(factory.save).to be_truthy
      expect(QcResult.all.count).to eq(3)
    end

    it 'produces sensible error messages if the resource is not valid' do
      factory = QcResultFactory.new([asset_1, asset_2, asset_3, asset_invalid_uuid])
      expect(factory).to_not be_valid
      expect(factory.errors.full_messages.first).to include(factory.resources.last.message_id)

      factory = QcResultFactory.new([asset_1, asset_2, asset_3, asset_invalid_key])
      expect(factory).to_not be_valid
      expect(factory.errors.full_messages.first).to include(factory.resources.last.message_id)
    end

    it '#save does not save any of the resources unless they are all valid' do
      factory = QcResultFactory.new([asset_1, asset_2, asset_3, asset_invalid_key])
      expect(factory).to_not be_valid
      expect(factory.save).to be_falsey
      expect(QcResult.all).to be_empty
    end
  end

  describe QcResultFactory::Resource do
    let(:asset) { create(:asset) }
    let(:qc_result_attributes) { attributes_for(:qc_result) }

    context 'Asset' do
      let(:attributes) { { uuid: asset.uuid }.merge(qc_result_attributes) }

      it 'is not valid unless the resource exists' do
        expect(QcResultFactory::Resource.new(attributes)).to be_valid
        expect(QcResultFactory::Resource.new(attributes.except(:uuid))).to_not be_valid
        expect(QcResultFactory::Resource.new(attributes.merge(uuid: SecureRandom.uuid))).to_not be_valid
      end

      it 'is not valid unless the qc result is valid' do
        expect(QcResultFactory::Resource.new(attributes.except(:key))).to_not be_valid
      end

      it '#save should create a qc_result record if valid' do
        resource = QcResultFactory::Resource.new(attributes)
        expect(resource.save).to be_truthy
        expect(QcResult.find(resource.qc_result.id)).to be_present

        resource = QcResultFactory::Resource.new(attributes.except(:uuid))
        expect(resource.save).to be_falsey
      end

      it 'produces a sensible error message identifier' do
        expect(QcResultFactory::Resource.new(attributes).message_id).to eq("Uuid - #{asset.uuid}")
        expect(QcResultFactory::Resource.new(qc_result_attributes).message_id).to eq('Uuid - blank')
      end
    end

    context 'Plate' do
      let(:plate) { create(:plate_with_empty_wells, well_count: 12) }

      it 'is not valid unless the well location is valid' do
        expect(QcResultFactory::Resource.new(qc_result_attributes.merge(uuid: plate.uuid, well_location: plate.wells.first.map.description))).to be_valid
        expect(QcResultFactory::Resource.new(qc_result_attributes.merge(uuid: plate.uuid, well_location: 'Z999'))).to_not be_valid
      end
    end

    context 'Sample' do
      let(:sample) { create(:sample_with_well) }

      it 'creates the asset as the primary receptacle' do
        expect(QcResultFactory::Resource.new(qc_result_attributes.merge(uuid: sample.uuid)).asset).to eq(sample.primary_receptacle)
      end
    end
  end
end
