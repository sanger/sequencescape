# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/sapio_reception_shared_context'

# Sapio reception from end to end, as from library plate manifests. How
# these specs work: spec/shared_contexts/sapio_reception_shared_context.rb
describe 'Sapio reception of library plates',
         :sapio_operations_endpoint_enabled, :sapio_reception_enabled do
  include_context 'with Sapio reception'

  # As from a library plate manifest: a plate of libraries, each with an i7
  # and an i5 oligo and a library type
  context 'with a plate of libraries with i7 and i5 oligos' do
    let(:library_type) { create(:library_type) }
    let(:payload_libraries_by_well) do
      { 'A1' => sample('SAPIO-1-1', i7: 'ACGTACGT', i5: 'TTGGCCAA',
                                    library_type: library_type.name),
        'B1' => sample('SAPIO-1-2', i7: 'CATGCATG', i5: 'AACCGGTT',
                                    library_type: library_type.name),
        'C1' => sample('SAPIO-1-3', i7: 'GTCAGTCA', i5: 'GGAATTCC',
                                    library_type: library_type.name) }
    end
    let!(:operation) do
      post_and_process(reception_request(plate('SAPIO-PLATE-1',
                                               payload_libraries_by_well)))
    end
    let(:received_plate) { Barcode.find_by!(barcode: 'SAPIO-PLATE-1').asset }

    it 'completes the reception' do
      expect(operation.reload.status).to eq('reception_completed')
    end

    # A library plate manifest's plate is a Stock Plate unless the manifest
    # chooses another purpose, such as Library Stock Plate
    it 'creates a 96-well Library Stock Plate' do
      expect(received_plate).to have_attributes(
        class: Plate, size: 96,
        purpose: have_attributes(name: 'Library Stock Plate')
      )
    end

    it 'puts each library in its well, with its oligos as tags' do
      expect(received_plate.wells.flat_map(&:aliquots).map do |aliquot|
        [aliquot.receptacle.map_description, aliquot.sample.sanger_sample_id,
         aliquot.tag.oligo, aliquot.tag2.oligo]
      end).to match_array(payload_libraries_by_well.map do |well, library|
        [well, library[:sanger_sample_id], library[:i7], library[:i5]]
      end)
    end

    it 'gives each aliquot the library type and its well as library' do
      expect(received_plate.wells.flat_map(&:aliquots).map do |aliquot|
        [aliquot.library_type, aliquot.library_id == aliquot.receptacle_id]
      end).to eq([[library_type.name, true]] * payload_libraries_by_well.size)
    end
  end

  # As from a library plate manifest: a plate of libraries, each with a tag
  # from a tag group by index, without a tag 2, and a library type
  context 'with a plate of libraries with tags from a tag group' do
    let(:tag_group) { create(:tag_group_with_tags, tag_count: 3) }
    let(:library_type) { create(:library_type) }
    let(:payload_libraries_by_well) do
      %w[A1 B1 C1].each.with_index(1).to_h do |well, index|
        [well, sample("SAPIO-1-#{index}", tag_group: tag_group.name,
                                          tag_index: index,
                                          library_type: library_type.name)]
      end
    end
    let!(:operation) do
      post_and_process(reception_request(plate('SAPIO-PLATE-1',
                                               payload_libraries_by_well)))
    end
    let(:received_plate) { Barcode.find_by!(barcode: 'SAPIO-PLATE-1').asset }

    it 'completes the reception' do
      expect(operation.reload.status).to eq('reception_completed')
    end

    it 'puts each library in its well, with its tag and no tag 2' do
      expect(received_plate.wells.flat_map(&:aliquots).map do |aliquot|
        [aliquot.receptacle.map_description, aliquot.sample.sanger_sample_id,
         aliquot.tag, aliquot.tag2_id]
      end).to match_array(payload_libraries_by_well.map do |well, library|
        [well, library[:sanger_sample_id],
         tag_group.tags.find_by(map_id: library[:tag_index]), -1]
      end)
    end
  end

  # As from a Chromium library plate manifest: a plate of libraries, each
  # with a well of a Chromium tag set's kit plate
  context 'with a plate of libraries with Chromium tags' do
    let(:chromium) { ApiOperation::Reception::Tags::Chromium }
    let(:tag_set) do
      tag_group =
        create(:tag_group_with_tags,
               tag_count: 2 * chromium::TAGS_PER_WELL,
               adapter_type: create(:adapter_type, name: 'Chromium'))
      create(:tag_set, tag_group: tag_group, tag2_group: nil)
    end
    # Each library's kit well is another library's well, so its tags can
    # only come from chromium_tag_well
    let(:payload_libraries_by_well) do
      { 'A1' => sample('SAPIO-1-1', chromium_tag_group: tag_set.name,
                                    chromium_tag_well: 'B1'),
        'B1' => sample('SAPIO-1-2', chromium_tag_group: tag_set.name,
                                    chromium_tag_well: 'A1') }
    end
    let!(:operation) do
      post_and_process(reception_request(plate('SAPIO-PLATE-1',
                                               payload_libraries_by_well)))
    end
    let(:received_plate) { Barcode.find_by!(barcode: 'SAPIO-PLATE-1').asset }

    it 'completes the reception' do
      expect(operation.reload.status).to eq('reception_completed')
    end

    it 'gives each library an aliquot for each tag of its kit well' do
      expect(received_plate.wells.flat_map(&:aliquots).map do |aliquot|
        [aliquot.receptacle.map_description, aliquot.sample.sanger_sample_id,
         aliquot.tag.map_id]
      end).to match_array(chromium.map_ids(2).map { ['A1', 'SAPIO-1-1', it] } +
                          chromium.map_ids(1).map { ['B1', 'SAPIO-1-2', it] })
    end

    it 'gives each aliquot tag depth 1 and its well as library' do
      expect(received_plate.wells.flat_map(&:aliquots).map do |aliquot|
        [aliquot.tag_depth, aliquot.library_id == aliquot.receptacle_id]
      end).to eq([[1, true]] * chromium::TAGS_PER_WELL *
                 payload_libraries_by_well.size)
    end
  end
end
