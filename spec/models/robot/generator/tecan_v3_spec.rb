# frozen_string_literal: true

# Test cases:
# 1. Cherrypick has <8 buffer addition steps total
# 2. Cherrypick has >8, <16 buffer addition steps
# 3. Cherrypick has >16 buffer addition steps
# 4. Cherrypick samples from a plate that has a skipped well
#    i.e. pick wells 1-6, 8-10 and carry out buffer additions for each of these
# 5. Cherrypick a full plate (96 wells)
# 6. Cherrypick has a mix of buffer and sample additions. For some wells,
#    take the full volume of sample, do not add any buffer i.e. these wells
#    do not require diluting
# 7. Cherrypick run that is just sample additions for all transfers, no buffer
#    additions at all (use the pick by volume approach?)
# 8. Run a cherrypick where at least 1 channel has been disabled on the
#    Tecan [N/A: It is disabled on the instrument itself]
# 9. Cherrypick from >1 source plate
# 10. With automated buffer addition for empty wells option enabled in Cherrypick
# 11. Partial destination plate with some filled wells and some empty wells

describe Robot::Generator::TecanV3 do
  let(:total_volume_to_cherrypick) { 180 }
  let(:batch) { instance_double(Batch, total_volume_to_cherrypick:) }
  let(:layout) { Robot::Verification::SourceDestBeds.new.layout_data_object(data_object) }
  let(:generator) { described_class.new(picking_data: data_object, batch: batch, layout: layout) }
  let(:source_barcode) { 'SQPD-9001-U' }
  let(:dest_barcode) { 'SQPD-9999-U' }
  let(:plate_size) { 96 }
  let(:source_data) do
    {
      source_barcode => {
        'name' => 'ABgene 0765',
        'plate_size' => plate_size
      }
    }
  end
  let(:data_object) do
    {
      'user' => 'user',
      'time' => 'Tue Oct 16 10:10:10 2025',
      'source' => source_data,
      'destination' => {
        dest_barcode => {
          'name' => 'ABgene 0800',
          'plate_size' => plate_size,
          'mapping' => mapping_data
        }
      }
    }
  end

  # Mapping data for the test cases:
  let(:indexes) { [] } # array or range of postions in column order, 1-based
  let(:skip_indexes) { [] } # optional array or range of positions to skip
  let(:no_buffer_indexes) { [] } # optional positions without buffer addition
  let(:number_of_rows) { 8 } # number of rows in the plate, used for calculating well locations in column order
  let(:mapping_data) do
    indexes.filter_map do |index|
      next if skip_indexes&.include?(index)

      location = Map::Coordinate.vertical_position_to_description(index, number_of_rows)
      if no_buffer_indexes&.include?(index)
        volume = total_volume_to_cherrypick
        buffer_volume = 0.0
      else
        volume = total_volume_to_cherrypick - 1 - index
        buffer_volume = total_volume_to_cherrypick - volume
      end
      { 'src_well' => [source_barcode, location], 'dst_well' => location,
        'volume' => volume, 'buffer_volume' => buffer_volume }
    end
  end
  # Expected output for the test cases.
  let(:expected_output) { File.read("spec/data/tecan_v3/case_#{case_num}.gwl") }

  before do
    allow(batch).to receive(:buffer_volume_for_empty_wells).and_return(nil)
  end

  shared_examples 'a TecanV3 generator' do
    it 'generates the expected output' do
      expect(generator.as_text).to eq expected_output
    end
  end

  context 'when Cherrypick has <8 buffer addition steps total' do
    # case_1: 7 buffer addition steps
    let(:indexes) { 1..7 }
    let(:case_num) { 1 }

    it_behaves_like 'a TecanV3 generator'
  end

  context 'when Cherrypick has >8, <16 buffer addition steps' do
    # case_2: 15 buffer addition steps
    let(:indexes) { 1..15 }
    let(:case_num) { 2 }

    it_behaves_like 'a TecanV3 generator'
  end

  context 'when Cherrypick has >16 buffer addition steps' do
    # case_3: 17 buffer addition steps
    let(:indexes) { 1..17 }
    let(:case_num) { 3 }

    it_behaves_like 'a TecanV3 generator'
  end

  context 'when Cherrypick samples from a plate that has a skipped well' do
    # i.e. pick wells 1-6, 8-10 and carry out buffer additions for each of these
    # case_4: 9 buffer addition steps; G1 is skipped.
    let(:indexes) { 1..10 }
    let(:skip_indexes) { [7] }
    let(:case_num) { 4 }

    it_behaves_like 'a TecanV3 generator'
  end

  context 'when Cherrypick a full plate (96 wells)' do
    # case_5: 96 buffer addition steps
    let(:indexes) { 1..96 }
    let(:case_num) { 5 }

    it_behaves_like 'a TecanV3 generator'
  end

  context 'when Cherrypick has a mix of buffer and sample additions' do
    # For some wells, take the full volume of sample, do not add any buffer
    # i.e. these wells do not require diluting
    # case_6: 10 sources wells, 5 with buffer additions, 5 without
    let(:indexes) { 1..10 }
    let(:no_buffer_indexes) { 1..5 }
    let(:case_num) { 6 }

    it_behaves_like 'a TecanV3 generator'
  end

  context 'when Cherrypick run that is just sample additions for all transfers' do
    # no buffer additions at all (use the pick by volume approach?)
    # case_7: 10 source wells, all without buffer additions
    let(:indexes) { 1..10 }
    let(:no_buffer_indexes) { 1..10 }
    let(:case_num) { 7 }

    it_behaves_like 'a TecanV3 generator'
  end

  context 'when Cherrypick from >1 source plate' do
    # case_9: 2 source plates, each with 9 source wells, with buffer additions
    let(:indexes) { 1..9 } # same for both plates
    let(:source2_barcode) { 'SQPD-9002-U' }
    let(:case_num) { 9 } # to find the fixture file
    let(:source_data) do
      {
        source_barcode => {
          'name' => 'ABgene 0765',
          'plate_size' => plate_size
        },
        source2_barcode => {
          'name' => 'ABgene 0765',
          'plate_size' => plate_size
        }
      }
    end
    # Mapping data for multiple source plates.
    let(:mapping_data) do
      dst_index = 1
      result = []
      source_data.each_key do |src_barcode|
        src_map = indexes.filter_map do |index|
          dst_index += 1
          src_location = Map::Coordinate.vertical_position_to_description(index, number_of_rows)
          dst_location = Map::Coordinate.vertical_position_to_description(dst_index, number_of_rows)
          volume = total_volume_to_cherrypick - 1 - index
          buffer_volume = total_volume_to_cherrypick - volume
          { 'src_well' => [src_barcode, src_location], 'dst_well' => dst_location,
            'volume' => volume, 'buffer_volume' => buffer_volume }
        end
        result.concat(src_map)
      end
      result
    end

    it_behaves_like 'a TecanV3 generator'
  end

  context 'with automated buffer addition for empty wells option enabled in Cherrypick' do
    # half plate of samples, half empty wells
    let(:indexes) { 1..48 }
    let(:case_num) { 10 }

    let(:mapping_data) do
      indexes.filter_map do |index|
        location = Map::Coordinate.vertical_position_to_description(index, number_of_rows)

        volume = total_volume_to_cherrypick - 1 - index
        buffer_volume = total_volume_to_cherrypick - volume

        { 'src_well' => [source_barcode, location], 'dst_well' => location,
          'volume' => volume, 'buffer_volume' => buffer_volume }
      end
    end

    before do
      allow(batch).to receive(:buffer_volume_for_empty_wells).and_return(120.0)

      dest_plate = create(:plate, barcode: dest_barcode, size: 96, sample_count: 0)
      allow(Plate).to receive(:find_by_barcode).with(dest_barcode).and_return(dest_plate)
    end

    it_behaves_like 'a TecanV3 generator'
  end

  context 'with automated buffer addition and a partial destination plate' do
    # partial plate containing 16 samples already
    # adding 48 empty wells, leaving 32 empty wells to fill with buffer
    let(:indexes) { 17..64 }
    let(:case_num) { 11 }

    let(:mapping_data) do
      indexes.filter_map do |index|
        location = Map::Coordinate.vertical_position_to_description(index, number_of_rows)

        volume = total_volume_to_cherrypick - 1 - index
        buffer_volume = total_volume_to_cherrypick - volume

        { 'src_well' => [source_barcode, location], 'dst_well' => location,
          'volume' => volume, 'buffer_volume' => buffer_volume }
      end
    end

    let(:dest_plate) { create(:plate_with_untagged_wells, barcode: dest_barcode, size: 96, sample_count: 16) }

    before do
      allow(batch).to receive(:buffer_volume_for_empty_wells).and_return(120.0)

      allow(Plate).to receive(:find_by_barcode).with(dest_barcode).and_return(dest_plate)
    end

    # it should not fill the 16 already filled wells with buffer, but should fill the 32 empty
    # wells with buffer, and add the 48 sample transfers as specified in the mapping data
    it_behaves_like 'a TecanV3 generator'
  end
end
