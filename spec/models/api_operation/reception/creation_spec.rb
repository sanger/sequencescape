# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::Reception::Creation do
  subject(:creation) { described_class.new(payload.labware) }

  let(:payload) do
    ApiOperation::Reception::Payload.new({ labware: }.to_json)
  end
  let(:created) { Barcode.find_by!(barcode: 'SAPIO-1').asset }

  before do
    create(:input_plate_purpose, name: 'Library Stock Plate')
    allow(PlateBarcode).to receive(:create_barcode)
    creation.call
  end

  # A payload sample, with the optional fields given
  def sample(**fields)
    { uuid: SecureRandom.uuid, study_uuid: SecureRandom.uuid,
      sanger_sample_id: "SAMPLE-#{SecureRandom.hex(4)}",
      supplier_sample_name: 'Supplier sample' }.merge(fields)
  end

  # A payload plate with a sample in each well from A1 down the first column
  def plate(barcode, *samples)
    receptacles = samples.each_with_index.map do |sample, index|
      { position: "#{('A'.ord + index).chr}1", uuid: SecureRandom.uuid,
        samples: [sample] }
    end
    { uuid: SecureRandom.uuid, barcode: barcode, type: 'plate96',
      receptacles: receptacles }
  end

  # A payload tube holding the samples
  def tube(barcode, *samples)
    { uuid: SecureRandom.uuid, barcode: barcode, type: 'tube',
      receptacles: [{ position: nil, uuid: SecureRandom.uuid,
                      samples: samples }] }
  end

  context 'with a plate whose samples have no tags' do
    let(:labware) { [plate('SAPIO-1', sample, sample)] }

    it 'creates a Stock Plate named after its barcode' do
      expect(created).to have_attributes(
        class: Plate, name: 'Plate SAPIO-1', size: 96,
        purpose: have_attributes(name: 'Stock Plate')
      )
    end

    it 'gives it only the barcode it arrived with' do
      expect(created.barcodes.map { [it.format, it.barcode] })
        .to eq([%w[external SAPIO-1]])
    end

    it 'does not ask Baracoda for a barcode' do
      expect(PlateBarcode).not_to have_received(:create_barcode)
    end

    it 'gives it its wells' do
      expect(created.wells.count).to eq(96)
    end
  end

  context 'with a plate whose samples have tags' do
    let(:labware) { [plate('SAPIO-1', sample(i7: 'ACGT'), sample)] }

    it 'creates a Library Stock Plate' do
      expect(created.purpose.name).to eq('Library Stock Plate')
    end
  end

  context 'with a tube of a sample without tags' do
    let(:labware) { [tube('SAPIO-1', sample)] }

    it 'creates a Standard sample tube' do
      expect(created).to be_a(SampleTube).and have_attributes(
        purpose: have_attributes(name: 'Standard sample')
      )
    end

    it 'gives it only the barcode it arrived with' do
      expect(created.barcodes.map { [it.format, it.barcode] })
        .to eq([%w[external SAPIO-1]])
    end
  end

  context 'with a tube of samples without tags' do
    let(:labware) { [tube('SAPIO-1', sample, sample)] }

    it 'creates a Standard sample tube' do
      expect(created.purpose.name).to eq('Standard sample')
    end
  end

  context 'with a tube of a sample with tags' do
    let(:labware) do
      [tube('SAPIO-1', sample(tag_group: 'Group', tag_index: 1))]
    end

    it 'creates a Standard library tube' do
      expect(created).to be_a(LibraryTube).and have_attributes(
        purpose: have_attributes(name: 'Standard library')
      )
    end
  end

  context 'with a tube of samples with tags' do
    let(:labware) do
      [tube('SAPIO-1', sample(i7: 'ACGT'), sample(i7: 'TGCA'))]
    end

    it 'creates a Standard MX tube' do
      expect(created).to be_a(MultiplexedLibraryTube).and have_attributes(
        purpose: have_attributes(name: 'Standard MX')
      )
    end
  end

  context 'with several labware' do
    let(:labware) do
      [plate('SAPIO-1', sample), tube('SAPIO-2', sample),
       tube('SAPIO-3', sample)]
    end

    it 'creates each' do
      expect(Barcode.where(barcode: %w[SAPIO-1 SAPIO-2 SAPIO-3]).count)
        .to eq(3)
    end
  end
end
