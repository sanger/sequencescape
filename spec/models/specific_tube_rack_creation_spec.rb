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
      error_messages = specific_tube_rack_creation.errors.full_messages.join(', ')
      expect(specific_tube_rack_creation.save).to be(true), "Failed to save: #{error_messages}"
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
      it_behaves_like 'with common tests'
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
            racked_tubes: []
          },
          {
            tube_rack_name: 'Tube Rack',
            tube_rack_barcode: 'TR00000002',
            tube_rack_purpose_uuid: child_tube_rack_purpose.uuid,
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
    end

    context 'with one rack and multiple tubes' do
      include_context 'with common test setup'

      let(:tube_rack_attributes) do
        [
          {
            tube_rack_name: 'Tube Rack',
            tube_rack_barcode: 'TR00000001',
            tube_rack_purpose_uuid: child_tube_rack_purpose.uuid,
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

  context 'when testing individual methods' do
    include_context 'with common setup'

    let(:creation_parameters) { { user:, tube_rack_attributes:, parent: } }

    let(:existing_tube_rack) { create(:tube_rack, name: 'TubeRack2') }
    let(:new_tube_rack_barcode_string) { 'TR10000001' }
    let(:new_tube_rack) { create(:tube_rack, name: 'TubeRack1') }
    let(:tube_rack_barcode_format) { :fluidx_barcode }

    describe '#handle_tube_rack_barcode' do
      before { allow(Barcode).to receive(:includes).with(:asset).and_return(Barcode) }

      context 'when the existing barcode record is nil' do
        let(:existing_tube_rack_barcode_record) { nil }
        let(:new_tube_rack_barcode_record) do
          create(:barcode, barcode: new_tube_rack_barcode_string, format: tube_rack_barcode_format)
        end

        before do
          allow(Barcode).to receive(:find_by).with(barcode: new_tube_rack_barcode_string).and_return(nil)
          allow(Barcode).to receive(:create!).with(
            labware: new_tube_rack,
            barcode: new_tube_rack_barcode_string,
            format: tube_rack_barcode_format
          ).and_return(new_tube_rack_barcode_record)
          # rubocop:disable RSpec/SubjectStub
          # rubocop doesn't understand we aren't stubbing the method
          allow(specific_tube_rack_creation).to receive(:create_new_barcode).and_call_original
          # rubocop:enable RSpec/SubjectStub
        end

        it 'calls create_new_barcode with the correct arguments' do
          specific_tube_rack_creation.send(:handle_tube_rack_barcode, new_tube_rack_barcode_string, new_tube_rack)

          # rubocop:disable RSpec/SubjectStub
          expect(specific_tube_rack_creation).to have_received(:create_new_barcode).with(
            new_tube_rack_barcode_string,
            new_tube_rack
          )
          # rubocop:enable RSpec/SubjectStub
        end
      end

      context 'when the barcode record is already in use' do
        let(:existing_tube_rack_barcode_string) { 'TR10000001' }
        let(:existing_tube_rack_barcode_record) do
          create(:barcode, barcode: existing_tube_rack_barcode_string, labware: existing_tube_rack)
        end

        before do
          allow(Barcode).to receive(:find_by).with(barcode: new_tube_rack_barcode_string).and_return(
            existing_tube_rack_barcode_record
          )
          # rubocop:disable RSpec/SubjectStub
          # rubocop doesn't understand we aren't stubbing the method
          allow(specific_tube_rack_creation).to receive(:redirect_existing_barcode).and_call_original
          # rubocop:enable RSpec/SubjectStub
        end

        # rubocop:disable RSpec/ExampleLength
        it 'calls redirect_existing_barcode with the correct arguments' do
          specific_tube_rack_creation.send(:handle_tube_rack_barcode, existing_tube_rack_barcode_string, new_tube_rack)

          # rubocop:disable RSpec/SubjectStub
          expect(specific_tube_rack_creation).to have_received(:redirect_existing_barcode).with(
            existing_tube_rack_barcode_record,
            new_tube_rack,
            existing_tube_rack_barcode_string
          )
          # rubocop:enable RSpec/SubjectStub
        end
        # rubocop:enable RSpec/ExampleLength
      end
    end

    describe '#create_new_barcode' do
      let(:tube_rack_barcode_format) { :test_format }

      before do
        allow(Barcode).to receive(:matching_barcode_format).with(new_tube_rack_barcode_string).and_return(
          tube_rack_barcode_format
        )
        allow(Barcode).to receive(:create!)
      end

      context 'when the barcode format is recognized' do
        it 'creates a new barcode with the correct attributes' do
          specific_tube_rack_creation.send(:create_new_barcode, new_tube_rack_barcode_string, new_tube_rack)

          expect(Barcode).to have_received(:create!).with(
            labware: new_tube_rack,
            barcode: new_tube_rack_barcode_string,
            format: tube_rack_barcode_format
          )
        end
      end

      context 'when the barcode format is not recognized' do
        let(:tube_rack_barcode_format) { nil }

        # rubocop:disable RSpec/ExampleLength
        it 'raises a StandardError with the correct message' do
          expect do
            specific_tube_rack_creation.send(:create_new_barcode, new_tube_rack_barcode_string, new_tube_rack)
          end.to raise_error(
            StandardError,
            "The tube rack barcode '#{new_tube_rack_barcode_string}' is not a recognised format."
          )
        end
        # rubocop:enable RSpec/ExampleLength
      end
    end

    describe '#redirect_existing_barcode' do
      let(:existing_tube_rack_barcode_record) { create(:barcode, labware: existing_labware) }

      context 'when the existing labware is a TubeRack' do
        let(:existing_labware) { create(:tube_rack) }

        before { allow(existing_tube_rack_barcode_record).to receive(:labware=).with(new_tube_rack) }

        # rubocop:disable RSpec/ExampleLength
        it 'redirects the barcode to the new tube rack' do
          specific_tube_rack_creation.send(
            :redirect_existing_barcode,
            existing_tube_rack_barcode_record,
            new_tube_rack,
            new_tube_rack_barcode_string
          )

          expect(existing_tube_rack_barcode_record).to have_received(:labware=).with(new_tube_rack)
        end
        # rubocop:enable RSpec/ExampleLength
      end

      context 'when the existing labware is not a TubeRack' do
        let(:existing_labware) { create(:plate) }

        # rubocop:disable RSpec/ExampleLength
        it 'raises a StandardError with the correct message' do
          expect do
            specific_tube_rack_creation.send(
              :redirect_existing_barcode,
              existing_tube_rack_barcode_record,
              new_tube_rack,
              new_tube_rack_barcode_string
            )
          end.to raise_error(
            StandardError,
            "The tube rack barcode '#{new_tube_rack_barcode_string}' is already in use " \
            'by another type of labware, cannot create tube rack.'
          )
        end
        # rubocop:enable RSpec/ExampleLength
      end
    end

    describe '#add_tube_rack_metadata' do
      let(:metadata_key) { 'tube_rack_barcode_key' }
      let(:poly_metadatum) do
        create(:poly_metadatum, metadatable: new_tube_rack, key: metadata_key, value: new_tube_rack_barcode_string)
      end

      before do
        allow(Rails.application.config).to receive(:tube_racks_config).and_return(tube_rack_barcode_key: metadata_key)
        allow(PolyMetadatum).to receive(:new).and_return(poly_metadatum)
        allow(poly_metadatum).to receive(:save).and_return(save_result)
      end

      context 'when the metadata saves successfully' do
        let(:save_result) { true }

        it 'creates a new PolyMetadatum with the correct attributes' do
          specific_tube_rack_creation.send(:add_tube_rack_metadata, new_tube_rack_barcode_string, new_tube_rack)

          expect(PolyMetadatum).to have_received(:new).with(
            key: metadata_key,
            value: new_tube_rack_barcode_string,
            metadatable_type: 'TubeRack',
            metadatable_id: new_tube_rack.id
          )
        end
      end

      context 'when the metadata does not save successfully' do
        let(:save_result) { false }

        # rubocop:disable RSpec/ExampleLength
        it 'raises a StandardError with the correct message' do
          expect do
            specific_tube_rack_creation.send(:add_tube_rack_metadata, new_tube_rack_barcode_string, new_tube_rack)
          end.to raise_error(
            StandardError,
            "New metadata for tube rack (key: #{metadata_key}, value: #{new_tube_rack_barcode_string}) did not save"
          )
        end
        # rubocop:enable RSpec/ExampleLength
      end
    end

    describe '#ensure_unique_tube_barcode' do
      let(:tube_barcode) { 'TB123456' }
      let(:existing_tube_barcode_record) { create(:barcode) }

      before do
        allow(Barcode).to receive(:includes).with(:asset).and_return(Barcode)
        allow(Barcode).to receive(:find_by).with(asset_id: tube_barcode).and_return(existing_tube_barcode_record)
      end

      context 'when the tube barcode is not in use' do
        let(:existing_tube_barcode_record) { nil }

        it 'does not raise an error' do
          expect { specific_tube_rack_creation.send(:ensure_unique_tube_barcode, tube_barcode) }.not_to raise_error
        end
      end

      context 'when the tube barcode is already in use' do
        it 'raises a StandardError with the correct message' do
          expect { specific_tube_rack_creation.send(:ensure_unique_tube_barcode, tube_barcode) }.to raise_error(
            StandardError,
            "The tube barcode '#{tube_barcode}' is already in use, cannot continue."
          )
        end
      end
    end

    describe '#check_tube_barcode_format' do
      let(:tube_barcode) { 'TB123456' }

      before { allow(Barcode).to receive(:matching_barcode_format).with(tube_barcode).and_return(barcode_format) }

      context 'when the barcode format is not recognized' do
        let(:barcode_format) { nil }

        it 'raises a StandardError with the correct message' do
          expect { specific_tube_rack_creation.send(:check_tube_barcode_format, tube_barcode) }.to raise_error(
            StandardError,
            "The tube barcode '#{tube_barcode}' is not a recognised format."
          )
        end
      end

      context 'when the barcode format is recognized but not fluidx' do
        let(:barcode_format) { :other_format }

        it 'raises a StandardError with the correct message' do
          expect { specific_tube_rack_creation.send(:check_tube_barcode_format, tube_barcode) }.to raise_error(
            StandardError,
            "The tube barcode '#{tube_barcode}' is not of the expected fluidx type."
          )
        end
      end

      context 'when the barcode format is fluidx' do
        let(:barcode_format) { :fluidx_barcode }

        it 'does not raise an error' do
          expect { specific_tube_rack_creation.send(:check_tube_barcode_format, tube_barcode) }.not_to raise_error
        end
      end
    end

    describe '#link_tube_to_rack' do
      let(:tube) { create(:tube, name: 'Tube1') }
      let(:tube_position) { 'A1' }
      let(:racked_tube) { create(:racked_tube, tube: tube, tube_rack: new_tube_rack, coordinate: tube_position) }

      before do
        allow(RackedTube).to receive(:new).and_return(racked_tube)
        allow(racked_tube).to receive(:save!).and_return(save_result)
      end

      context 'when the racked tube saves successfully' do
        let(:save_result) { true }

        it 'creates a new RackedTube with the correct attributes' do
          specific_tube_rack_creation.send(:link_tube_to_rack, tube, new_tube_rack, tube_position)

          expect(RackedTube).to have_received(:new).with(
            tube: tube,
            tube_rack: new_tube_rack,
            coordinate: tube_position
          )
        end
      end

      context 'when the racked tube does not save successfully' do
        let(:save_result) { false }

        # rubocop:disable RSpec/ExampleLength
        it 'raises an StandardError with the correct message' do
          expect do
            specific_tube_rack_creation.send(:link_tube_to_rack, tube, new_tube_rack, tube_position)
          end.to raise_error(
            StandardError,
            "The tube 'Tube1' could not be linked to the tube rack 'TubeRack1' at position 'A1'."
          )
        end
        # rubocop:enable RSpec/ExampleLength
      end
    end
  end
end
