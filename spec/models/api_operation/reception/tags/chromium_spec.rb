# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::Reception::Tags::Chromium do
  subject(:scheme) { described_class.new(samples, input) }

  let(:input) do
    ApiOperation::Reception::Validation::Input.build(labware, labware)
  end
  let(:labware) { [plate_with(samples.zip)] }

  # Two wells' worth of tags (A1 and B1)
  let(:tag_group) do
    create(:tag_group_with_tags,
           tag_count: 2 * described_class::TAGS_PER_WELL,
           adapter_type: create(:adapter_type, name: 'Chromium'))
  end
  let(:tag_set) { create(:tag_set, tag_group: tag_group, tag2_group: nil) }

  # A sample in the receptacle at the index, with the Chromium fields
  def sample(index, **fields)
    ApiOperation::Reception::Payload::PayloadSample.new(
      uuid: SecureRandom.uuid, study_uuid: SecureRandom.uuid,
      sanger_sample_id: "SAMPLE-#{index}",
      supplier_sample_name: "Supplier sample #{index}",
      fields: fields.stringify_keys,
      pointer: "/labware/0/receptacles/#{index}/samples/0"
    )
  end

  # A plate with a well for each list of samples, A1 onwards
  def plate_with(samples_by_well)
    receptacles =
      samples_by_well.each_with_index.map do |well_samples, index|
        ApiOperation::Reception::Payload::PayloadReceptacle.new(
          position: "#{('A'..'H').to_a[index]}1", uuid: SecureRandom.uuid,
          samples: well_samples, pointer: "/labware/0/receptacles/#{index}"
        )
      end
    ApiOperation::Reception::Payload::PayloadLabware.new(
      uuid: SecureRandom.uuid, barcode: 'PLATE-1', type: 'plate96',
      receptacles: receptacles, pointer: '/labware/0'
    )
  end

  def pointer(index, field)
    "/labware/0/receptacles/#{index}/samples/0/#{field}"
  end

  it 'gives a well four consecutive tags, by column' do
    expect([1, 2, 9].map { described_class.map_ids(it) })
      .to eq([[1, 2, 3, 4], [5, 6, 7, 8], [33, 34, 35, 36]])
  end

  context 'with existing tag sets and wells' do
    let(:samples) do
      [sample(0, chromium_tag_group: tag_set.name, chromium_tag_well: 'A1'),
       sample(1, chromium_tag_group: tag_set.name.upcase,
                 chromium_tag_well: 'B1')]
    end

    it 'finds no errors' do
      expect(scheme.errors).to be_empty
    end
  end

  context 'with a zero-padded well' do
    let(:samples) do
      [sample(0, chromium_tag_group: tag_set.name, chromium_tag_well: 'B01')]
    end

    it 'reads it as the unpadded well' do
      expect(scheme.errors).to be_empty
    end
  end

  context 'with a tag set without its well' do
    let(:samples) { [sample(0, chromium_tag_group: tag_set.name)] }

    it 'reports the tag set' do
      expect(scheme.errors).to eq(
        [{ pointer: pointer(0, 'chromium_tag_group'),
           detail: 'chromium_tag_group needs a chromium_tag_well' }]
      )
    end
  end

  context 'with a tag set that does not exist, named by several samples' do
    let(:samples) do
      [sample(0, chromium_tag_group: 'Unknown', chromium_tag_well: 'A1'),
       sample(1, chromium_tag_group: 'Unknown', chromium_tag_well: 'B1')]
    end

    it 'reports it once, at its first sample' do
      expect(scheme.errors).to eq(
        [{ pointer: pointer(0, 'chromium_tag_group'),
           detail: 'No visible single-index Chromium tag set named Unknown ' \
                   '(used by 2 samples)' }]
      )
    end
  end

  context 'with a tag set whose group is not a Chromium group' do
    let(:other_set) do
      create(:tag_set, tag_group: create(:tag_group_with_tags, tag_count: 4),
                       tag2_group: nil)
    end
    let(:samples) do
      [sample(0, chromium_tag_group: other_set.name, chromium_tag_well: 'A1')]
    end

    it 'reports the tag set' do
      expect(scheme.errors.sole[:pointer])
        .to eq(pointer(0, 'chromium_tag_group'))
    end
  end

  %w[I1 A13 a1 X].each do |well|
    context "with #{well} as the well" do
      let(:samples) do
        [sample(0, chromium_tag_group: tag_set.name, chromium_tag_well: well)]
      end

      it 'reports the well' do
        expect(scheme.errors).to eq(
          [{ pointer: pointer(0, 'chromium_tag_well'),
             detail: "#{well} is not a well of a 96-well kit plate" }]
        )
      end
    end
  end

  context 'with a well whose tags the group does not have' do
    let(:samples) do
      [sample(0, chromium_tag_group: tag_set.name, chromium_tag_well: 'C1'),
       sample(1, chromium_tag_group: tag_set.name, chromium_tag_well: 'C1')]
    end

    it 'reports it once, at its first sample' do
      expect(scheme.errors).to eq(
        [{ pointer: pointer(0, 'chromium_tag_well'),
           detail: "Chromium tag set #{tag_set.name} doesn't have the 4 " \
                   'tags of well C1 (used by 2 samples)' }]
      )
    end
  end

  context 'with a sample sharing its receptacle' do
    let(:samples) do
      [sample(0, chromium_tag_group: tag_set.name, chromium_tag_well: 'A1')]
    end
    let(:other) do
      sample(1).with(pointer: '/labware/0/receptacles/0/samples/1')
    end
    let(:labware) { [plate_with([[samples.first, other]])] }

    it 'reports the receptacle' do
      expect(scheme.errors).to eq(
        [{ pointer: '/labware/0/receptacles/0',
           detail: 'A receptacle with Chromium tags holds one sample, not 2' }]
      )
    end
  end

  describe '#oligos' do
    let(:samples) do
      [sample(0, chromium_tag_group: tag_set.name, chromium_tag_well: 'B1')]
    end

    it "gives the oligos of the well's four tags, an aliquot each" do
      expected = (5..8).map { [tag_group.tags.find_by(map_id: it).oligo, nil] }
      expect(scheme.oligos(samples.first)).to eq(expected)
    end
  end
end
