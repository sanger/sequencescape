# frozen_string_literal: true

require 'rails_helper'

RSpec.describe QcResultFactory, type: :model, qc_result: true do
  describe 'multiple resources' do
    let(:asset_1) { attributes_for(:qc_result).merge(uuid: create(:asset).uuid) }
    let(:asset_2) { attributes_for(:qc_result).merge(uuid: create(:asset).uuid) }
    let(:asset_3) { attributes_for(:qc_result).merge(uuid: create(:asset).uuid) }
    let(:asset_invalid_uuid) { attributes_for(:qc_result) }
    let(:asset_invalid_key) { attributes_for(:qc_result).except(:key).merge(uuid: create(:asset).uuid) }

    context 'passed as an array' do
      it 'creates a resource for each item passed' do
        factory = QcResultFactory.new([asset_1, asset_2, asset_3])
        expect(factory.resources.count).to eq(3)
      end

      it 'creates an assay to group all items passed' do
        factory = QcResultFactory.new([asset_1, asset_2, asset_3])
        expect(factory.qc_assay).to be_a(QcAssay)
        factory.resources.each do |resource|
          expect(resource.qc_assay).to eq(factory.qc_assay)
        end
      end

      it '#save saves all of the resources if they are valid' do
        factory = QcResultFactory.new([asset_1, asset_2, asset_3])
        expect(factory).to be_valid
        expect(factory.save).to be_truthy
        expect(QcResult.all.count).to eq(3)
        expect(QcAssay.all.count).to eq(1)
        QcResult.all.each do |qc_result|
          expect(qc_result.qc_assay).to eq QcAssay.last
        end
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
        expect(QcAssay.all).to be_empty
      end
    end

    context 'passed as an object' do
      it 'creates a resource for each item passed' do
        factory = QcResultFactory.new(qc_results: [asset_1, asset_2, asset_3], lot_number: 'LN1234567')
        expect(factory.resources.count).to eq(3)
      end

      it 'creates an assay to group all items passed' do
        factory = QcResultFactory.new(qc_results: [asset_1, asset_2, asset_3], lot_number: 'LN1234567')
        expect(factory.qc_assay).to be_a(QcAssay)
        expect(factory.qc_assay.lot_number).to eq('LN1234567')
        factory.resources.each do |resource|
          expect(resource.qc_assay).to eq(factory.qc_assay)
        end
      end

      it '#save saves all of the resources if they are valid' do
        factory = QcResultFactory.new(qc_results: [asset_1, asset_2, asset_3], lot_number: 'LN1234567')
        expect(factory).to be_valid
        expect(factory.save).to be_truthy
        expect(QcResult.all.count).to eq(3)
        expect(QcAssay.all.count).to eq(1)
        QcResult.all.each do |qc_result|
          expect(qc_result.qc_assay).to eq QcAssay.last
        end
      end
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
        expect(QcResultFactory::Resource.new(attributes).message_id).to eq("Asset identifier - #{asset.uuid}")
        expect(QcResultFactory::Resource.new(qc_result_attributes).message_id).to eq('Asset identifier - blank')
      end
    end

    context 'Plate' do
      let(:plate) { create(:plate_with_empty_wells, well_count: 12) }

      it 'is not valid unless the well location is valid' do
        expect(QcResultFactory::Resource.new(qc_result_attributes.merge(uuid: plate.uuid, well_location: plate.wells.first.map.description))).to be_valid
        expect(QcResultFactory::Resource.new(qc_result_attributes.merge(uuid: plate.uuid, well_location: 'Z999'))).to_not be_valid
      end
    end

    context 'Barcode' do
      let(:plate) { create(:plate_with_empty_wells, well_count: 12) }

      it 'will create a valid resource with a valid barcode' do
        expect(QcResultFactory::Resource.new(qc_result_attributes.merge(barcode: plate.barcodes.first.barcode, well_location: plate.wells.first.map.description))).to be_valid
      end

      it 'will not create a valid resource with an invalid barcode' do
      end
    end

    context 'Sample' do
      let(:sample) { create(:sample_with_well) }

      it 'creates the asset as the primary receptacle' do
        expect(QcResultFactory::Resource.new(qc_result_attributes.merge(uuid: sample.uuid)).asset).to eq(sample.primary_receptacle)
      end
    end

    context 'Working Dilution' do
      let!(:user) { create(:user) }
      let(:attributes) { qc_result_attributes.merge(key: 'concentration', assay_type: 'Working dilution', value: '3.4567') }

      context 'with dilution factor' do
        let!(:stock_plate) { create(:full_stock_plate, well_count: 3, dilution_factor: 10) }
        let!(:working_dilution_plate) { create(:working_dilution_plate, parents: [stock_plate], well_count: 3, dilution_factor: 10) }
        let(:working_dilution_attributes) { attributes.merge(uuid: working_dilution_plate.uuid, well_location: working_dilution_plate.wells.first.map.description) }

        it 'resource indicates if it is a working dilution' do
          resource = QcResultFactory::Resource.new(working_dilution_attributes)
          expect(resource).to be_working_dilution
        end

        it 'resource indicates if it is a concentration' do
          resource = QcResultFactory::Resource.new(working_dilution_attributes)
          expect(resource).to be_concentration
        end

        it '#update_parent_well creates a new qc result for the parent well' do
          resource = QcResultFactory::Resource.new(working_dilution_attributes)
          resource.update_parent_well
          qc_result = QcResult.find_by(asset_id: stock_plate.wells.first.id)
          expect(qc_result).to be_present
          expect(qc_result.value).to eq('34.567')
        end

        it '#save will update the parent well if it is a working dilution' do
          resource = QcResultFactory::Resource.new(working_dilution_attributes)
          resource.save
          qc_result = QcResult.find_by(asset_id: stock_plate.wells.first.id)
          expect(qc_result).to be_present
          expect(qc_result.value).to eq('34.567')
        end
      end

      context 'with no dilution factor' do
        let!(:stock_plate) { create(:full_stock_plate, well_count: 3, dilution_factor: nil) }
        let!(:working_dilution_plate) { create(:working_dilution_plate, parents: [stock_plate], well_count: 3, dilution_factor: nil) }
        let(:working_dilution_attributes) { attributes.merge(uuid: working_dilution_plate.uuid, well_location: working_dilution_plate.wells.first.map.description) }

        it '#save will not update the parent well if it is a working dilution' do
          resource = QcResultFactory::Resource.new(working_dilution_attributes)
          resource.save
          expect(QcResult.find_by(asset_id: stock_plate.wells.first.id)).to_not be_present
        end
      end
    end
  end
end
