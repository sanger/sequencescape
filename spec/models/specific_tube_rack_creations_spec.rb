# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SpecificTubeRackCreation do
  shared_context 'with common setup' do
    subject(:specific_tube_rack_creation) { described_class.new(creation_parameters) }

    let(:child_tube_rack_purpose) { create(:tube_rack_purpose) }
    let(:child_tube_purpose) { create(:sample_tube_purpose) }
    let(:tube_rack_attributes) do
      [
        {
          tube_rack_name: 'Tube Rack',
          tube_rack_barcode: 'TR00000001',
          tube_rack_purpose_uuid: child_tube_rack_purpose.uuid,
          tube_rack_metadata_key: 'tube_rack_barcode',
          racked_tubes: [
            {
              tube_barcode: 'ST00000001',
              tube_name: 'SEQ:NT1A:A1',
              tube_purpose_uuid: child_tube_purpose.uuid,
              tube_position: 'A1',
              parent_uuids: [parent.uuid]
            }
          ]
        }
      ]
    end

    let(:user) { create(:user) }
    let(:parent) { create(:plate) }
  end

  shared_context 'with common test setup' do
    before do
      expect(specific_tube_rack_creation.save).to (be true),
      -> { "Failed to save: #{specific_tube_rack_creation.errors.full_messages}" }
    end

    let(:first_child_rack) { specific_tube_rack_creation.children.first }
  end

  shared_examples 'with common tests' do
    it 'creates one child' do
      expect(specific_tube_rack_creation.children.count).to eq 1
    end

    it 'creates a tube rack' do
      expect(first_child_rack).to be_a TubeRack
    end

    it 'sets the purpose' do
      expect(first_child_rack.purpose).to eq child_tube_rack_purpose
    end

    it 'sets plates as parents' do
      specific_tube_rack_creation.children.each { |child| expect(child.parents).to include(parent) }
    end
  end

  shared_examples 'a specific tube rack creator' do
    include_context 'with common setup'

    describe '#save' do
      include_context 'with common test setup'
      include_examples 'with common tests'
    end
  end

  context 'with no tubes' do
    include_context 'with common setup'

    let(:creation_parameters) { { user:, tube_rack_attributes:, parent: } }

    context 'with one rack and zero tubes' do
      let(:tube_rack_attributes) do
        [
          {
            tube_rack_name: 'Tube Rack',
            tube_rack_barcode: 'TR00000001',
            tube_rack_purpose_uuid: child_tube_rack_purpose.uuid,
            tube_rack_metadata_key: 'tube_rack_barcode',
            racked_tubes: []
          }
        ]
      end

      it_behaves_like 'a specific tube rack creator'
    end

    context 'with two racks and zero tubes' do
      let(:tube_rack_attributes) do
        [
          {
            tube_rack_name: 'Tube Rack',
            tube_rack_barcode: 'TR00000001',
            tube_rack_purpose_uuid: child_tube_rack_purpose.uuid,
            tube_rack_metadata_key: 'tube_rack_barcode',
            racked_tubes: []
          },
          {
            tube_rack_name: 'Tube Rack',
            tube_rack_barcode: 'TR00000002',
            tube_rack_purpose_uuid: child_tube_rack_purpose.uuid,
            tube_rack_metadata_key: 'tube_rack_barcode',
            racked_tubes: []
          }
        ]
      end

      it_behaves_like 'a specific tube rack creator'
    end

    context 'with an unknown tube rack purpose' do
      let(:unknown_tube_rack_purpose_uuid) { 'unknown-tube-rack-purpose-uuid' }
      let(:tube_rack_attributes) do
        [
          {
            tube_rack_name: 'Tube Rack',
            tube_rack_barcode: 'TR00000001',
            tube_rack_purpose_uuid: unknown_tube_rack_purpose_uuid,
            tube_rack_metadata_key: 'tube_rack_barcode',
            racked_tubes: []
          }
        ]
      end

      let(:expected_error_msg) { "The tube rack purpose with UUID '#{unknown_tube_rack_purpose_uuid}' was not found." }

      it 'rejects the save if the tube rack purpose is not recognised' do
        expect { specific_tube_rack_creation.save }.to raise_error(StandardError, expected_error_msg)
      end
    end
  end

  context 'with tubes' do
    include_context 'with common setup'

    let(:creation_parameters) { { user:, tube_rack_attributes:, parent: } }

    context 'with one rack and one tube' do
      include_context 'with common test setup'

      let(:tube_rack_attributes) do
        [
          {
            tube_rack_name: 'Tube Rack',
            tube_rack_barcode: 'TR00000001',
            tube_rack_purpose_uuid: child_tube_rack_purpose.uuid,
            tube_rack_metadata_key: 'tube_rack_barcode',
            racked_tubes: [
              {
                tube_barcode: 'ST00000001',
                tube_name: 'SEQ:NT1A:A1',
                tube_purpose_uuid: child_tube_purpose.uuid,
                tube_position: 'A1',
                parent_uuids: [parent.uuid]
              }
            ]
          }
        ]
      end

      it_behaves_like 'a specific tube rack creator'

      it 'creates a linked racked tube' do
        expect(first_child_rack.tubes.count).to eq 1
      end

      it 'sets the tube purpose' do
        expect(first_child_rack.tubes.first.purpose).to eq child_tube_purpose
      end

      it 'sets the tube name' do
        expect(first_child_rack.tubes.first.name).to eq 'SEQ:NT1A:A1'
      end

      it 'sets the tube barcode' do
        expect(first_child_rack.tubes.first.primary_barcode.barcode).to eq 'ST00000001'
      end

      it 'sets the tube as a racked tube of the tube rack' do
        expect(first_child_rack.racked_tubes.first.tube_id).to eq first_child_rack.tubes.first.id
      end

      it 'sets the tube coordinate in the rack' do
        expect(first_child_rack.racked_tubes.first.coordinate).to eq 'A1'
      end

      it 'creates tube rack metadata' do
        expect(
          PolyMetadatum.find_by(key: 'tube_rack_barcode', metadatable: first_child_rack.id).value
        ).to eq 'TR00000001'
      end
    end

    context 'with one rack and multiple tubes' do
      include_context 'with common test setup'

      let(:tube_rack_attributes) do
        [
          {
            tube_rack_name: 'Tube Rack',
            tube_rack_barcode: 'TR00000001',
            tube_rack_purpose_uuid: child_tube_rack_purpose.uuid,
            tube_rack_metadata_key: 'tube_rack_barcode',
            racked_tubes: [
              {
                tube_barcode: 'ST00000001',
                tube_name: 'SEQ:NT1A:A1',
                tube_purpose_uuid: child_tube_purpose.uuid,
                tube_position: 'A1',
                parent_uuids: [parent.uuid]
              },
              {
                tube_barcode: 'ST00000002',
                tube_name: 'SEQ:NT2B:B1',
                tube_purpose_uuid: child_tube_purpose.uuid,
                tube_position: 'B1',
                parent_uuids: [parent.uuid]
              },
              {
                tube_barcode: 'ST00000003',
                tube_name: 'SEQ:NT3C:C1',
                tube_purpose_uuid: child_tube_purpose.uuid,
                tube_position: 'C1',
                parent_uuids: [parent.uuid]
              }
            ]
          }
        ]
      end

      it_behaves_like 'a specific tube rack creator'

      it 'creates multiple linked racked tubes' do
        expect(first_child_rack.tubes.count).to eq 3
      end

      it 'sets the tube purpose' do
        expect(first_child_rack.tubes.last.purpose).to eq child_tube_purpose
      end

      it 'sets the tube name' do
        expect(first_child_rack.tubes.last.name).to eq 'SEQ:NT3C:C1'
      end

      it 'sets the tube barcode' do
        expect(first_child_rack.tubes.first.primary_barcode.barcode).to eq 'ST00000001'
      end

      it 'sets the tubes as racked tubes of the tube rack' do
        expect(first_child_rack.racked_tubes.last.tube_id).to eq first_child_rack.tubes.last.id
      end

      it 'sets the tube coordinate in the rack' do
        expect(first_child_rack.racked_tubes.last.coordinate).to eq 'C1'
      end
    end

    context 'with two racks and one tube each' do
      include_context 'with common test setup'

      let(:child_tube_rack_purpose2) { create(:tube_rack_purpose, name: 'SPR Rack Purpose') }
      let(:child_tube_purpose2) { create(:sample_tube_purpose, name: 'SPR Tube Purpose') }
      let(:last_child_rack) { specific_tube_rack_creation.children.last }

      let(:tube_rack_attributes) do
        [
          {
            tube_rack_name: 'Tube Rack',
            tube_rack_barcode: 'TR00000001',
            tube_rack_purpose_uuid: child_tube_rack_purpose.uuid,
            tube_rack_metadata_key: 'tube_rack_barcode',
            racked_tubes: [
              {
                tube_barcode: 'ST00000001',
                tube_name: 'SEQ:NT1A:A1',
                tube_purpose_uuid: child_tube_purpose.uuid,
                tube_position: 'A1',
                parent_uuids: [parent.uuid]
              }
            ]
          },
          {
            tube_rack_name: 'Tube Rack',
            tube_rack_barcode: 'TR00000002',
            tube_rack_purpose_uuid: child_tube_rack_purpose2.uuid,
            tube_rack_metadata_key: 'tube_rack_barcode',
            racked_tubes: [
              {
                tube_barcode: 'ST00000002',
                tube_name: 'SPR:NT4D:D1',
                tube_purpose_uuid: child_tube_purpose2.uuid,
                tube_position: 'D1',
                parent_uuids: [parent.uuid]
              }
            ]
          }
        ]
      end

      it_behaves_like 'a specific tube rack creator'

      it 'creates a linked racked tube for the first rack' do
        expect(first_child_rack.tubes.count).to eq 1
      end

      it 'creates a linked racked tube for the second rack' do
        expect(last_child_rack.tubes.count).to eq 1
      end

      it 'sets the tube purpose for the tube in the first rack' do
        expect(first_child_rack.tubes.last.purpose).to eq child_tube_purpose
      end

      it 'sets the tube purpose for the tube in the second rack' do
        expect(last_child_rack.tubes.last.purpose).to eq child_tube_purpose2
      end

      it 'sets the name of the tube in the first rack' do
        expect(first_child_rack.tubes.first.name).to eq 'SEQ:NT1A:A1'
      end

      it 'sets the name of the tube in the second rack' do
        expect(last_child_rack.tubes.first.name).to eq 'SPR:NT4D:D1'
      end

      it 'sets the barcode of the tube in the first rack' do
        expect(first_child_rack.tubes.first.primary_barcode.barcode).to eq 'ST00000001'
      end

      it 'sets the barcode of the tube in the second rack' do
        expect(last_child_rack.tubes.first.primary_barcode.barcode).to eq 'ST00000002'
      end

      it 'sets the racked tubes of the first tube rack' do
        expect(first_child_rack.racked_tubes.first.tube_id).to eq first_child_rack.tubes.first.id
      end

      it 'sets the racked tubes of the second tube rack' do
        expect(last_child_rack.racked_tubes.first.tube_id).to eq last_child_rack.tubes.first.id
      end

      it 'sets the coordinate of the tube in the first rack' do
        expect(first_child_rack.racked_tubes.first.coordinate).to eq 'A1'
      end

      it 'sets the coordinate of the tube in the second rack' do
        expect(last_child_rack.racked_tubes.first.coordinate).to eq 'D1'
      end
    end

    context 'with an unknown tube purpose' do
      let(:unknown_tube_purpose_uuid) { 'unknown-tube-purpose-uuid' }
      let(:tube_rack_attributes) do
        [
          {
            tube_rack_name: 'Tube Rack',
            tube_rack_barcode: 'TR00000001',
            tube_rack_purpose_uuid: child_tube_rack_purpose.uuid,
            tube_rack_metadata_key: 'tube_rack_barcode',
            racked_tubes: [
              {
                tube_barcode: 'ST00000001',
                tube_name: 'SEQ:NT1A:A1',
                tube_purpose_uuid: unknown_tube_purpose_uuid,
                tube_position: 'A1',
                parent_uuids: [parent.uuid]
              }
            ]
          }
        ]
      end

      let(:expected_error_msg) { "The tube purpose with UUID '#{unknown_tube_purpose_uuid}' was not found." }

      it 'rejects the save if the tube purpose is not recognised' do
        expect { specific_tube_rack_creation.save }.to raise_error(StandardError, expected_error_msg)
      end
    end
  end
end
