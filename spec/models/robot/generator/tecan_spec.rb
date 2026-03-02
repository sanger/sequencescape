# frozen_string_literal: true

describe Robot::Generator::Tecan do
  shared_examples 'a generator' do
    describe '.as_text' do
      let(:batch) { instance_double(Batch, total_volume_to_cherrypick: 13) }
      let(:layout) { Robot::Verification::SourceDestBeds.new.layout_data_object(data_object) }
      let(:generator) { described_class.new(picking_data: data_object, batch: batch, layout: layout) }

      context 'when mapping wells from 1 96 well source plate to 1 96 well destination plate' do
        before do
          allow(batch).to receive(:buffer_volume_for_empty_wells).and_return(nil)
        end

        it 'returns a String object' do
          expect(generator.as_text).to be_a String
        end

        it 'generates the expected output' do
          expect(generator.as_text).to eq expected_output
        end

        it 'has a header section' do
          assert_match(/^C;\nC; This file created by (.+?) on (.+?)\nC;\n/, generator.as_text)
        end

        it 'contains buffers' do
          assert_match(/(?:A;BUFF;;.*?\nD;DEST[0-9].*?\nW;\n)?/, generator.as_text)
        end

        it 'contains a footer' do
          assert_match(/C;\n(C; SCRC[0-9] = [0-9]+\n)+C;\nC; DEST[0-9] = SQPD-[0-9]+-U\n$/, generator.as_text)
        end
      end
    end
  end

  context 'with one source' do
    let(:expected_output) { File.read('test/data/tecan/original.gwl') }
    let(:data_object) do
      {
        'user' => 'xyz987',
        'time' => 'Tue Sep 29 11:00:42 2009',
        'source' => {
          '95020' => {
            'name' => 'ABgene 0765',
            'plate_size' => 96
          }
        },
        'destination' => {
          'SQPD-12345-U' => {
            'name' => 'ABgene 0800',
            'plate_size' => 96,
            'mapping' => [
              { 'src_well' => %w[95020 B7], 'dst_well' => 'A1', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 C7], 'dst_well' => 'B1', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 D7], 'dst_well' => 'C1', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 E7], 'dst_well' => 'D1', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 H7], 'dst_well' => 'E1', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 D8], 'dst_well' => 'F1', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 E8], 'dst_well' => 'G1', 'volume' => 6.77, 'buffer_volume' => 6.23 },
              { 'src_well' => %w[95020 A8], 'dst_well' => 'H1', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 G8], 'dst_well' => 'A2', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 H8], 'dst_well' => 'B2', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 A9], 'dst_well' => 'C2', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 B9], 'dst_well' => 'D2', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 C9], 'dst_well' => 'E2', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 D9], 'dst_well' => 'F2', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 E9], 'dst_well' => 'G2', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 F9], 'dst_well' => 'H2', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 G9], 'dst_well' => 'A3', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 H9], 'dst_well' => 'B3', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 C10], 'dst_well' => 'C3', 'volume' => 9.48, 'buffer_volume' => 3.52 },
              { 'src_well' => %w[95020 E10], 'dst_well' => 'D3', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 F10], 'dst_well' => 'E3', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 H10], 'dst_well' => 'F3', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 D11], 'dst_well' => 'G3', 'volume' => 6.91, 'buffer_volume' => 6.09 },
              { 'src_well' => %w[95020 A11], 'dst_well' => 'H3', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 B11], 'dst_well' => 'A4', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 E11], 'dst_well' => 'B4', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 G11], 'dst_well' => 'C4', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 B12], 'dst_well' => 'D4', 'volume' => 7.83, 'buffer_volume' => 5.17 },
              { 'src_well' => %w[95020 A12], 'dst_well' => 'E4', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 C12], 'dst_well' => 'F4', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 D12], 'dst_well' => 'G4', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[95020 F12], 'dst_well' => 'H4', 'volume' => 13, 'buffer_volume' => 0.0 }
            ]
          }
        }
      }
    end

    it_behaves_like 'a generator'

    describe '#buffers' do
      let(:batch) { instance_double(Batch, buffer_volume_for_empty_wells: 10.0) }
      let(:data_object) do
        {
          'destination' => {
            'SQPD-12345-U' => {
              'name' => 'ABgene 0800',
              'plate_size' => 96,
              'mapping' => [
                { 'src_well' => %w[95020 A1], 'dst_well' => 'A1', 'volume' => 13, 'buffer_volume' => 0.0 },
                { 'dst_well' => 'B1', 'buffer_volume' => 10.0 }
              ]
            }
          },
          'source' => {
            '95020' => { 'name' => 'ABgene 0765', 'plate_size' => 96 }
          }
        }
      end
      let(:generator) { described_class.new(picking_data: data_object, batch: batch, layout: nil) }
      let(:dest_plate) { create(:plate_with_empty_wells, well_count: 4, barcode: 'SQPD-12345-U') }

      before do
        allow(Plate).to receive(:find_by_barcode).with('SQPD-12345-U').and_return(dest_plate)
      end

      it 'skips buffer for sample wells when src_well is present and total_volume <= mapping["volume"]' do
        allow(generator).to receive(:total_volume).and_return(13)
        result = generator.buffers(data_object)
        expect(result).not_to include('A;95020')
      end

      it 'includes buffer for empty wells (no src_well)' do
        allow(generator).to receive(:total_volume).and_return(13)
        result = generator.buffers(data_object)
        expect(result).to include('A;')
      end
    end

    describe '#data_object_for_buffers' do
      let(:batch) { build(:batch) }

      let(:metadata_key_automatic_buffer_addition) { 'automatic_buffer_addition' }
      let(:metadata_key_buffer_vol) { 'buffer_volume_for_empty_wells' }

      let(:poly_metadatum_automatic_buffer_addition) do
        create(:poly_metadatum, metadatable: batch, key: metadata_key_automatic_buffer_addition, value: '1')
      end
      let(:poly_metadatum_buffer_vol) do
        create(:poly_metadatum, metadatable: batch, key: metadata_key_buffer_vol, value: 120.0)
      end

      let(:generator) { described_class.new(picking_data: nil, batch: batch, layout: nil) }
      let(:time_of_test) { Time.now.utc }

      let(:input_data_object) do
        {
          'destination' => {
            'SQPD-9101' => {
              'name' => 'ABgene 0800',
              'plate_size' => 4,
              'control' => false,
              'mapping' => [
                { 'src_well' => %w[SQPD-9089 A1], 'dst_well' => 'A1', 'volume' => 100.0, 'buffer_volume' => 0.0 },
                { 'src_well' => %w[SQPD-9090 A2], 'dst_well' => 'B1', 'volume' => 100.0, 'buffer_volume' => 0.0 }
              ]
            }
          },
          'source' => {
            'SQPD-9089' => { 'name' => 'ABgene 0800', 'plate_size' => 4, 'control' => false },
            'SQPD-9090' => { 'name' => 'ABgene 0800', 'plate_size' => 4, 'control' => false }
          },
          'time' => time_of_test,
          'user' => 'admin'
        }
      end

      let(:expected_output) do
        {
          'destination' => {
            'SQPD-9101' => {
              'name' => 'ABgene 0800',
              'plate_size' => 4,
              'mapping' => [
                { 'src_well' => %w[SQPD-9089 A1], 'dst_well' => 'A1', 'volume' => 100.0, 'buffer_volume' => 0.0 },
                { 'src_well' => %w[SQPD-9090 A2], 'dst_well' => 'B1', 'volume' => 100.0, 'buffer_volume' => 0.0 },
                { 'dst_well' => 'C1', 'buffer_volume' => 120.0 },
                { 'dst_well' => 'D1', 'buffer_volume' => 120.0 }
              ]
            }
          }
        }
      end

      before do
        # Stub Plate.find_by_barcode and well lookup logic
        test_plate = create(:plate, barcode: 'SQPD-9101', size: 4)
        allow(Plate).to receive(:find_by_barcode).with('SQPD-9101').and_return(test_plate)
        allow(test_plate).to receive(:find_well_by_name) do |well_name|
          # Only A1 and B1 are present and non-empty, C1 and D1 are empty
          case well_name
          when 'A1'
            position = Map.for_position_on_plate(1, 96, test_plate.asset_shape).first
            create(:well_with_sample_and_plate, map: position, plate: test_plate)
          when 'B1'
            position = Map.for_position_on_plate(2, 96, test_plate.asset_shape).first
            create(:well_with_sample_and_plate, map: position, plate: test_plate)
          when 'C1'
            position = Map.for_position_on_plate(3, 96, test_plate.asset_shape).first
            create(:well, map: position, plate: test_plate)
          when 'D1'
            position = Map.for_position_on_plate(4, 96, test_plate.asset_shape).first
            create(:well, map: position, plate: test_plate)
          end
        end
        allow(generator).to receive(:description_to_column_index) do |well_name, _|
          # Map A1->1, B1->2, C1->3, D1->4
          { 'A1' => 1, 'B1' => 2, 'C1' => 3, 'D1' => 4 }[well_name]
        end
        allow(generator).to receive(:column_index_to_description) do |index, _|
          # Map 1->A1, 2->B1, 3->C1, 4->D1
          { 1 => 'A1', 2 => 'B1', 3 => 'C1', 4 => 'D1' }[index]
        end
        # create the poly metadata for buffer addition and volume in the batch
        poly_metadatum_automatic_buffer_addition
        poly_metadatum_buffer_vol
      end

      it 'adds buffer entries for empty destination wells' do
        result = generator.data_object_for_buffers(input_data_object)
        expect(result).to eq(expected_output)
      end

      it 'returns original data_object if buffer_volume_for_empty_wells is nil' do
        allow(batch).to receive(:buffer_volume_for_empty_wells).and_return(nil)
        result = generator.data_object_for_buffers(input_data_object)
        expect(result).to eq(input_data_object)
      end
    end
  end

  context 'with multiple sources' do
    let(:expected_output) { File.read('test/data/tecan/SQPD-12345-U.gwl') }
    let(:data_object) do
      {
        'user' => 'xyz987',
        'time' => 'Fri Nov 27 10:11:13 2009',
        'source' => {
          '122289' => {
            'name' => 'ABgene 0765',
            'plate_size' => 96
          },
          '80785' => {
            'name' => 'ABgene 0765',
            'plate_size' => 96
          },
          '122290' => {
            'name' => 'ABgene 0765',
            'plate_size' => 96
          }
        },
        'destination' => {
          'SQPD-12345-U' => {
            'name' => 'ABgene 0800',
            'plate_size' => 96,
            'mapping' => [
              { 'src_well' => %w[122289 G7], 'dst_well' => 'D4', 'volume' => 3.33, 'buffer_volume' => 9.67 },
              { 'src_well' => %w[80785 A1], 'dst_well' => 'E4', 'volume' => 13, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[122289 H7], 'dst_well' => 'F4', 'volume' => 3.27, 'buffer_volume' => 9.73 },
              { 'src_well' => %w[122290 A1], 'dst_well' => 'E9', 'volume' => 2.8, 'buffer_volume' => 10.2 },
              { 'src_well' => %w[122290 B1], 'dst_well' => 'F9', 'volume' => 4.08, 'buffer_volume' => 8.92 }
            ]
          }
        }
      }
    end

    it_behaves_like 'a generator'
  end

  context 'with pooling' do
    let(:expected_output) { File.read('test/data/tecan/pooled_cherrypick.gwl') }
    let(:data_object) do
      {
        'user' => 'xyz987',
        'time' => 'Fri Nov 27 10:11:13 2009',
        'source' => {
          '1220415828863' => {
            'name' => 'ABgene 0765',
            'plate_size' => 96
          }
        },
        'destination' => {
          'SQPD-12345-U' => {
            'name' => 'ABgene 0800',
            'plate_size' => 96,
            'mapping' => [
              { 'src_well' => %w[1220415828863 A1], 'dst_well' => 'A1', 'volume' => 13.0, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[1220415828863 A2], 'dst_well' => 'A1', 'volume' => 13.0, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[1220415828863 A3], 'dst_well' => 'A1', 'volume' => 13.0, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[1220415828863 A4], 'dst_well' => 'A1', 'volume' => 13.0, 'buffer_volume' => 0.0 },
              { 'src_well' => %w[1220415828863 A5], 'dst_well' => 'A1', 'volume' => 13.0, 'buffer_volume' => 0.0 }
            ]
          }
        }
      }
    end

    it_behaves_like 'a generator'
  end
end
