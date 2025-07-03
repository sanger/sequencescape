# frozen_string_literal: true

require 'rails_helper'

# The Quad creator takes 4 parent 96 well plates or size 96 tube-racks
# and transfers them onto a new 384 well plate
RSpec.describe Plate::QuadCreator do
  subject(:quad_creator) { described_class.new(creation_options) }

  let(:target_purpose) { create(:plate_purpose, size: 384) }
  let(:user) { create(:user) }
  let(:creation_options) { { parent_barcodes: parent_barcodes_hash, target_purpose: target_purpose, user: user } }

  before { allow(PlateBarcode).to receive(:create_barcode).and_return(build(:plate_barcode)) }

  describe '#target_coordinate_for' do
    [
      [0, 'A1', 'A1'],
      [1, 'A1', 'B1'],
      [2, 'A1', 'A2'],
      [3, 'A1', 'B2'],
      [0, 'H12', 'O23'],
      [1, 'H12', 'P23'],
      [2, 'H12', 'O24'],
      [3, 'H12', 'P24']
    ].each do |quad_index, source_coordinate, target_coordinate|
      it "Transfers quadrant #{quad_index} well #{source_coordinate} to #{target_coordinate}" do
        expect(described_class.target_coordinate_for(source_coordinate, quad_index)).to eq target_coordinate
      end
    end
  end

  context 'when loading from barcodes' do
    let(:creation_options) { { parent_barcodes: parent_barcodes_hash, target_purpose: target_purpose, user: user } }

    context 'when a barcode is invalid' do
      let(:parent_barcodes_hash) { { 'quad_1' => 'INVALID' } }

      it { is_expected.not_to be_valid }

      it 'produces a useful error' do
        quad_creator.valid?
        expect(quad_creator.errors.full_messages).to include('Parent barcodes Quad 1 (INVALID) could not be found')
      end
    end

    context 'when a parent is not a plate or rack' do
      let(:tube) { create(:tube) }

      # this should pass in the tube, not the barcode
      let(:parent_barcodes_hash) { { 'quad_1' => tube.machine_barcode } }

      it { is_expected.not_to be_valid }

      it 'produces a useful error' do
        quad_creator.valid?
        expect(quad_creator.errors.full_messages).to include(
          "Parent barcodes Quad 1 (#{tube.machine_barcode}) is not a plate or tube rack"
        )
      end
    end

    context 'when a parent is the wrong size' do
      let(:plate) { create(:plate, size: 384) }

      # this should pass in the plate, not the barcode
      let(:parent_barcodes_hash) { { 'quad_1' => plate.machine_barcode } }

      it { is_expected.not_to be_valid }

      it 'produces a useful error' do
        quad_creator.valid?
        expect(quad_creator.errors.full_messages).to include(
          "Parent barcodes Quad 1 (#{plate.machine_barcode}) is the wrong size"
        )
      end
    end
  end

  context 'with parent plates' do
    context 'with 4 parents' do
      let(:occupied_wells) { [0, 95] }
      let(:number_of_parents) { 4 }

      # 2 wells in each, A1 & H12
      let(:parents) { create_list(:plate_with_untagged_wells, number_of_parents, occupied_well_index: occupied_wells) }
      let(:parent_barcodes_hash) do
        {
          'quad_1' => parents[0].machine_barcode,
          'quad_2' => parents[1].machine_barcode,
          'quad_3' => parents[2].machine_barcode,
          'quad_4' => parents[3].machine_barcode
        }
      end
      let(:quad_1_wells) { parents[0].wells.index_by(&:map_description) }
      let(:quad_2_wells) { parents[1].wells.index_by(&:map_description) }
      let(:quad_3_wells) { parents[2].wells.index_by(&:map_description) }
      let(:quad_4_wells) { parents[3].wells.index_by(&:map_description) }

      describe '#save' do
        context 'when complete' do
          before { quad_creator.save }

          it 'will create a new plate of the selected purpose' do
            expect(quad_creator.target_plate.purpose).to eq target_purpose
          end

          it 'will transfer the material from the source plates' do
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

          it 'will set each parent as a parent plate of the target' do
            parents.each { |parent| expect(quad_creator.target_plate.parents).to include(parent) }
          end
        end

        it 'records an asset creation' do
          expect { quad_creator.save }.to change(AssetCreation, :count).by(1)
        end

        it 'creates the correct transfer request collection' do
          expected_transfers = number_of_parents * occupied_wells.length
          expect { quad_creator.save }.to change(TransferRequestCollection, :count).by(1).and change(
            TransferRequest,
            :count
          ).by(expected_transfers)
        end

        it 'creates a custom metadatum collection and custom metadata' do
          expect { quad_creator.save }.to change(CustomMetadatumCollection, :count).by(1).and change(
            CustomMetadatum,
            :count
          ).by(4)
        end
      end
    end

    context 'with 1 parent' do
      let(:parents) { create_list(:plate_with_untagged_wells, 1, occupied_well_index: [0, 95]) } # 2 wells, A1 & H12
      let(:parent_barcodes_hash) { { 'quad_3' => parents[0].machine_barcode } }
      let(:quad_3_wells) { parents[0].wells.index_by(&:map_description) }

      before { quad_creator.save }

      it 'will transfer the material from the source plates' do
        well_hash = quad_creator.target_plate.wells.index_by(&:map_description)
        expect(well_hash['A2'].samples).to eq(quad_3_wells['A1'].samples)
        expect(well_hash['O24'].samples).to eq(quad_3_wells['H12'].samples)
      end
    end

    context 'with zero parents' do
      let(:parent_barcodes_hash) { {} }

      it { is_expected.not_to be_valid }

      it 'produces a useful error' do
        quad_creator.valid?
        expect(quad_creator.errors.full_messages).to include('Parent barcodes Please fill in at least one quadrant.')
      end
    end
  end

  context 'with parent tube racks' do
    context 'with 4 parents' do
      let(:parents) { create_list(:tube_rack_with_tubes, 4) }
      let(:parent_barcodes_hash) do
        {
          'quad_1' => parents[0].machine_barcode,
          'quad_2' => parents[1].machine_barcode,
          'quad_3' => parents[2].machine_barcode,
          'quad_4' => parents[3].machine_barcode
        }
      end
      let(:quad_1_tubes) { parents[0].tubes.index_by { |tube| tube.racked_tube.coordinate } }
      let(:quad_2_tubes) { parents[1].tubes.index_by { |tube| tube.racked_tube.coordinate } }
      let(:quad_3_tubes) { parents[2].tubes.index_by { |tube| tube.racked_tube.coordinate } }
      let(:quad_4_tubes) { parents[3].tubes.index_by { |tube| tube.racked_tube.coordinate } }

      describe '#save' do
        before { quad_creator.save }

        it 'will create a new plate of the selected purpose' do
          expect(quad_creator.target_plate.purpose).to eq target_purpose
        end

        it 'will transfer the material from the source racks' do
          well_hash = quad_creator.target_plate.wells.index_by(&:map_description)
          expect(well_hash['A1'].samples).to eq(quad_1_tubes['A1'].samples)
          expect(well_hash['B1'].samples).to eq(quad_2_tubes['A1'].samples)
          expect(well_hash['A2'].samples).to eq(quad_3_tubes['A1'].samples)
          expect(well_hash['B2'].samples).to eq(quad_4_tubes['A1'].samples)
          expect(well_hash['O23'].samples).to eq(quad_1_tubes['H12'].samples)
          expect(well_hash['P23'].samples).to eq(quad_2_tubes['H12'].samples)
          expect(well_hash['O24'].samples).to eq(quad_3_tubes['H12'].samples)
          expect(well_hash['P24'].samples).to eq(quad_4_tubes['H12'].samples)
        end

        it 'will set each parent as a parent rack of the target' do
          parents.each { |parent| expect(quad_creator.target_plate.parents).to include(parent) }
        end
      end
    end
  end

  context 'with a mixture of parent plates and racks' do
    # 2 wells in each, A1 & H12
    let(:parents_plates) { create_list(:plate_with_untagged_wells, 2, occupied_well_index: [0, 95]) }
    let(:parents_racks) { create_list(:tube_rack_with_tubes, 2) }

    let(:parent_barcodes_hash) do
      {
        'quad_1' => parents_plates[0].machine_barcode,
        'quad_2' => parents_plates[1].machine_barcode,
        'quad_3' => parents_racks[0].machine_barcode,
        'quad_4' => parents_racks[1].machine_barcode
      }
    end

    let(:quad_1_wells) { parents_plates[0].wells.index_by(&:map_description) }
    let(:quad_2_wells) { parents_plates[1].wells.index_by(&:map_description) }
    let(:quad_3_tubes) { parents_racks[0].tubes.index_by { |tube| tube.racked_tube.coordinate } }
    let(:quad_4_tubes) { parents_racks[1].tubes.index_by { |tube| tube.racked_tube.coordinate } }

    describe '#save' do
      before { quad_creator.save }

      it 'will create a new plate of the selected purpose' do
        expect(quad_creator.target_plate.purpose).to eq target_purpose
      end

      it 'will transfer the material from the sources' do
        well_hash = quad_creator.target_plate.wells.index_by(&:map_description)
        expect(well_hash['A1'].samples).to eq(quad_1_wells['A1'].samples)
        expect(well_hash['B1'].samples).to eq(quad_2_wells['A1'].samples)
        expect(well_hash['A2'].samples).to eq(quad_3_tubes['A1'].samples)
        expect(well_hash['B2'].samples).to eq(quad_4_tubes['A1'].samples)
        expect(well_hash['O23'].samples).to eq(quad_1_wells['H12'].samples)
        expect(well_hash['P23'].samples).to eq(quad_2_wells['H12'].samples)
        expect(well_hash['O24'].samples).to eq(quad_3_tubes['H12'].samples)
        expect(well_hash['P24'].samples).to eq(quad_4_tubes['H12'].samples)
      end

      it 'will set each parent as a parent rack or plate of the target' do
        parents_plates
          .concat(parents_racks)
          .each { |parent| expect(quad_creator.target_plate.parents).to include(parent) }
      end
    end
  end
end
