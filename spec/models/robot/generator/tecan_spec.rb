# frozen_string_literal: true

describe Robot::Generator::Tecan, type: :model do
  before { create(:full_plate) }

  shared_examples 'a generator' do
    describe '.as_text' do
      let(:batch) { instance_double(Batch, total_volume_to_cherrypick: 13) }
      let(:layout) { Robot::Verification::SourceDestBeds.new.layout_data_object(data_object) }
      let(:generator) { described_class.new(picking_data: data_object, batch: batch, layout: layout) }

      context 'when mapping wells from 1 96 well source plate to 1 96 well destination plate' do
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
          assert_match(/C;\n(C; SCRC[0-9] = [0-9]+\n)+C;\nC; DEST[0-9] = DN[0-9]+U\n$/, generator.as_text)
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
          'DN12345U' => {
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
  end

  context 'with multiple sources' do
    let(:expected_output) { File.read('test/data/tecan/DN12345U.gwl') }
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
          'DN12345U' => {
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
          'DN12345U' => {
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
