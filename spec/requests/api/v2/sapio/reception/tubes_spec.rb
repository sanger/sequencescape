# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/sapio_reception_shared_context'

# Sapio reception from end to end, as from tube manifests. How these specs
# work: spec/shared_contexts/sapio_reception_shared_context.rb
describe 'Sapio reception of tubes',
         :sapio_operations_endpoint_enabled, :sapio_reception_enabled do
  include_context 'with Sapio reception'

  # As from a sample tube manifest: tubes of one sample each, without tags
  context 'with tubes of one sample each' do
    let(:payload_samples_by_tube) do
      { 'SAPIO-TUBE-1' => sample('SAPIO-1-1'),
        'SAPIO-TUBE-2' => sample('SAPIO-1-2'),
        'SAPIO-TUBE-3' => sample('SAPIO-1-3') }
    end
    let!(:operation) do
      tubes = payload_samples_by_tube.map do |barcode, sample|
        tube(barcode, sample)
      end
      post_and_process(reception_request(*tubes))
    end
    let(:received_tubes) do
      payload_samples_by_tube.keys.index_with do |barcode|
        Barcode.find_by!(barcode:).asset
      end
    end

    it 'completes the reception' do
      expect(operation.reload.status).to eq('reception_completed')
    end

    it 'creates a Standard sample tube for each' do
      expect(received_tubes.values).to all(
        have_attributes(class: SampleTube,
                        purpose: have_attributes(name: 'Standard sample'))
      )
    end

    # A manifest's sample tube has a Sanger barcode
    it 'gives each tube only the barcode it arrived with' do
      expect(received_tubes.transform_values do |tube|
        tube.barcodes.map { [it.format, it.barcode] }
      end).to eq(payload_samples_by_tube.keys.index_with { [['external', it]] })
    end

    it 'puts each sample in its tube' do
      expect(received_tubes.transform_values do |tube|
        tube.aliquots.map { it.sample.sanger_sample_id }
      end).to eq(payload_samples_by_tube.transform_values do |payload_sample|
        [payload_sample[:sanger_sample_id]]
      end)
    end

    it 'gives each aliquot the study, no tags, tag depth 1 and no library' do
      expect(received_tubes.values.flat_map(&:aliquots).map do |aliquot|
        [aliquot.study, aliquot.tag_id, aliquot.tag2_id, aliquot.tag_depth,
         aliquot.library_id]
      end).to eq([[study, -1, -1, 1, nil]] * payload_samples_by_tube.size)
    end
  end

  # As from a control tube manifest: tubes of one control sample each
  context 'with control tubes' do
    let(:payload_samples_by_tube) do
      { 'SAPIO-TUBE-1' => sample('SAPIO-1-1', control_type: 'positive'),
        'SAPIO-TUBE-2' => sample('SAPIO-1-2', control_type: 'negative') }
    end
    let!(:operation) do
      tubes = payload_samples_by_tube.map do |barcode, sample|
        tube(barcode, sample)
      end
      post_and_process(reception_request(*tubes))
    end
    let(:received_tubes) do
      payload_samples_by_tube.keys.index_with do |barcode|
        Barcode.find_by!(barcode:).asset
      end
    end

    it 'completes the reception' do
      expect(operation.reload.status).to eq('reception_completed')
    end

    it 'puts a control of its type in each tube' do
      expect(received_tubes.transform_values do |tube|
        sample = tube.aliquots.sole.sample
        [sample.sanger_sample_id, sample.control, sample.control_type]
      end).to eq('SAPIO-TUBE-1' => ['SAPIO-1-1', true, 'positive'],
                 'SAPIO-TUBE-2' => ['SAPIO-1-2', true, 'negative'])
    end
  end

  # As from a library tube manifest with tag sequences: tubes of one library
  # each, with an i7 oligo and a library type
  context 'with library tubes' do
    let(:library_type) { create(:library_type) }
    let(:payload_libraries_by_tube) do
      { 'SAPIO-TUBE-1' => sample('SAPIO-1-1', i7: 'ACGTACGT',
                                              library_type: library_type.name),
        'SAPIO-TUBE-2' => sample('SAPIO-1-2', i7: 'CATGCATG',
                                              library_type: library_type.name) }
    end
    let!(:operation) do
      tubes = payload_libraries_by_tube.map do |barcode, library|
        tube(barcode, library)
      end
      post_and_process(reception_request(*tubes))
    end
    let(:received_tubes) do
      payload_libraries_by_tube.keys.index_with do |barcode|
        Barcode.find_by!(barcode:).asset
      end
    end

    it 'completes the reception' do
      expect(operation.reload.status).to eq('reception_completed')
    end

    it 'creates a Standard library tube for each' do
      expect(received_tubes.values).to all(
        have_attributes(class: LibraryTube,
                        purpose: have_attributes(name: 'Standard library'))
      )
    end

    it 'puts each library in its tube, tagged with its i7 oligo' do
      expect(received_tubes.transform_values do |tube|
        aliquot = tube.aliquots.sole
        [aliquot.sample.sanger_sample_id, aliquot.tag.oligo, aliquot.tag2_id]
      end).to eq('SAPIO-TUBE-1' => ['SAPIO-1-1', 'ACGTACGT', -1],
                 'SAPIO-TUBE-2' => ['SAPIO-1-2', 'CATGCATG', -1])
    end

    it 'gives each aliquot the library type and its tube as library' do
      expect(received_tubes.values.flat_map(&:aliquots).map do |aliquot|
        [aliquot.library_type, aliquot.library_id == aliquot.receptacle_id]
      end).to eq([[library_type.name, true]] * payload_libraries_by_tube.size)
    end
  end

  # As from a sample tube manifest with its VOLUME (ul), CONC. (ng/ul) and
  # GENOME SIZE columns filled in
  context 'with a tube whose sample gives its measurements' do
    let!(:operation) do
      measured = sample('SAPIO-1-1', volume: 12.5, concentration: 10,
                                     genome_size: 3100)
      post_and_process(reception_request(tube('SAPIO-TUBE-1', measured)))
    end
    let(:received_sample) { Sample.find_by!(sanger_sample_id: 'SAPIO-1-1') }

    it 'completes the reception' do
      expect(operation.reload.status).to eq('reception_completed')
    end

    it "keeps the measurements in the sample's metadata" do
      expect(received_sample.sample_metadata).to have_attributes(
        volume: '12.5', concentration: '10', genome_size: 3100
      )
    end
  end
end
