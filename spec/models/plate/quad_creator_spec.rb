# frozen_string_literal: true

require 'rails_helper'

# The Quad creator takes 4 parent 96 well plates or size 96 tube-racks
# and transfers them onto a new 384 well plate
RSpec.describe Plate::QuadCreator, type: :model do
  context 'with 4 parent plates' do
    let(:parents) { create_list :plate_with_untagged_wells, 4, occupied_well_index: [0,95] }
    let(:target_purpose) { create :plate_purpose, size: 384 }
    let(:parents_hash) do
      {
        quad_1: parents[0],
        quad_2: parents[1],
        quad_3: parents[2],
        quad_4: parents[3]
      }
    end
    let(:user) { create :user }

    let(:quad_1_wells) { parents[0].wells.index_by(&:map_description) }
    let(:quad_2_wells) { parents[1].wells.index_by(&:map_description) }
    let(:quad_3_wells) { parents[2].wells.index_by(&:map_description) }
    let(:quad_4_wells) { parents[3].wells.index_by(&:map_description) }

    let(:quad_creator) do
      described_class.new(parents: parents_hash, target_purpose: target_purpose, user: user)
    end

    setup do
      expect(PlateBarcode).to receive(:create).and_return(build(:plate_barcode, barcode: 1000))
    end

    describe '#save' do
      before { quad_creator.save }

      it 'will create a new plate of the selected purpose' do
        expect(quad_creator.target_plate.purpose).to eq target_purpose
      end

      it 'will transfer the material from the source plates' do
        # create transfer requests, in a transfer request collection
        # specifies source well, destination well and state of transfer (pending, passed etc.)
        # pass the transfer requests
        # where do the actual aliquots get created?
        well_hash = quad_creator.target_plate.wells.index_by(&:map_description)
        expect(well_hash['A1'].samples).to eq(quad_1_wells['A1'].samples)
        expect(well_hash['B1'].samples).to eq(quad_2_wells['A1'].samples)
        expect(well_hash['A2'].samples).to eq(quad_3_wells['A1'].samples)
        expect(well_hash['B2'].samples).to eq(quad_4_wells['A1'].samples)
        expect(well_hash['O23'].samples).to eq(quad_1_wells['H12'].samples)
        expect(well_hash['P23'].samples).to eq(quad_2_wells['H12'].samples)
        expect(well_hash['O24'].samples).to eq(quad_3_wells['H12'].samples)
        expect(well_hash['P24'].samples).to eq(quad_4_wells['H12'].samples)
      end

      it 'will set each parent as a parent plate of the target'
      it 'records an asset creation'
      it 'records plate metadata (custom_metadatum_collection) with quadrant -> stock plate barcodes?'
      it 'creates the correct transfer request collection'
    end
  end
end
