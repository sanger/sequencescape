# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/sapio_reception_shared_context'

# Sapio reception from end to end, as from multiplexed library tube
# manifests. How these specs work:
# spec/shared_contexts/sapio_reception_shared_context.rb
describe 'Sapio reception of multiplexed library tubes',
         :sapio_operations_endpoint_enabled, :sapio_reception_enabled do
  include_context 'with Sapio reception'

  # As from a multiplexed library tube manifest with tag sequences: libraries
  # in one tube, each with an i7 and an i5 oligo, without library fields
  context 'with a tube of libraries with i7 and i5 oligos' do
    let(:payload_libraries) do
      [sample('SAPIO-1-1', i7: 'ACGTACGT', i5: 'TTGGCCAA'),
       sample('SAPIO-1-2', i7: 'CATGCATG', i5: 'AACCGGTT'),
       sample('SAPIO-1-3', i7: 'GTCAGTCA', i5: 'GGAATTCC')]
    end
    let!(:operation) do
      post_and_process(reception_request(tube('SAPIO-TUBE-1',
                                              *payload_libraries)))
    end
    let(:received_tube) { Barcode.find_by!(barcode: 'SAPIO-TUBE-1').asset }

    it 'completes the reception' do
      expect(operation.reload.status).to eq('reception_completed')
    end

    it 'creates a Standard MX tube' do
      expect(received_tube).to have_attributes(
        class: MultiplexedLibraryTube,
        purpose: have_attributes(name: 'Standard MX')
      )
    end

    # A manifest's MX tube has a Sanger barcode
    it 'gives the tube only the barcode it arrived with' do
      expect(received_tube.barcodes.map { [it.format, it.barcode] })
        .to eq([%w[external SAPIO-TUBE-1]])
    end

    it 'tags each library with its oligos, in the Magic Tag Group' do
      expect(received_tube.aliquots.map do |aliquot|
        [aliquot.sample.sanger_sample_id,
         *[aliquot.tag, aliquot.tag2].map { [it.tag_group.name, it.oligo] }]
      end).to match_array(payload_libraries.map do |library|
        [library[:sanger_sample_id], ['Magic Tag Group', library[:i7]],
         ['Magic Tag Group', library[:i5]]]
      end)
    end

    # A manifest also makes a library tube for each sample: the library of
    # the sample's aliquot in the MX tube
    # (SampleManifest::MultiplexedLibraryBehaviour)
    it 'gives each aliquot the study, tag depth 1 and the tube as library' do
      expect(received_tube.aliquots.map do |aliquot|
        [aliquot.study, aliquot.library, aliquot.tag_depth]
      end).to eq(
        [[study, received_tube.receptacle, 1]] * payload_libraries.size
      )
    end

    it 'creates no labware other than the tube' do
      expect(Labware.all).to contain_exactly(received_tube)
    end
  end

  # As from a multiplexed library tube manifest: libraries in one tube, each
  # with a tag and a tag 2 from tag groups by index, a library type and
  # insert sizes
  context 'with a tube of libraries with tags from tag groups' do
    let(:tag_group) { create(:tag_group_with_tags, tag_count: 3) }
    let(:tag2_group) { create(:tag_group_with_tags, tag_count: 3) }
    let(:library_type) { create(:library_type) }
    let(:payload_libraries) do
      (1..3).map do |index|
        sample("SAPIO-1-#{index}",
               tag_group: tag_group.name, tag_index: index,
               tag2_group: tag2_group.name, tag2_index: index,
               library_type: library_type.name,
               insert_size_from: 100, insert_size_to: 200)
      end
    end
    let!(:operation) do
      post_and_process(reception_request(tube('SAPIO-TUBE-1',
                                              *payload_libraries)))
    end
    let(:received_tube) { Barcode.find_by!(barcode: 'SAPIO-TUBE-1').asset }

    it 'completes the reception' do
      expect(operation.reload.status).to eq('reception_completed')
    end

    it 'gives each library its tags, library type and insert sizes' do
      expect(received_tube.aliquots.map do |aliquot|
        [aliquot.sample.sanger_sample_id, aliquot.tag, aliquot.tag2,
         aliquot.library_type, aliquot.insert_size_from,
         aliquot.insert_size_to]
      end).to match_array(payload_libraries.map do |library|
        [library[:sanger_sample_id],
         tag_group.tags.find_by(map_id: library[:tag_index]),
         tag2_group.tags.find_by(map_id: library[:tag2_index]),
         library_type.name, 100, 200]
      end)
    end
  end
end
