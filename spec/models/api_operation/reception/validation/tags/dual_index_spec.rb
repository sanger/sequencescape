# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::Reception::Validation::Tags::DualIndex do
  subject(:scheme) { described_class.new(samples, input) }

  let(:input) do
    ApiOperation::Reception::Validation::Input.build(labware, labware)
  end
  let(:labware) { [plate_with(samples.zip)] }

  # Tags for wells A1 and B1 in both groups
  let(:tag_set) do
    create(:tag_set, tag_group: create(:tag_group_with_tags, tag_count: 2),
                     tag2_group: create(:tag_group_with_tags, tag_count: 2))
  end

  # A sample in the receptacle at the index, with the dual index fields
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

  context 'with an existing tag set and wells' do
    let(:samples) do
      [sample(0, dual_index_tag_set: tag_set.name, dual_index_tag_well: 'A1'),
       sample(1, dual_index_tag_set: tag_set.name.upcase,
                 dual_index_tag_well: 'b01')]
    end

    it 'finds no errors, ignoring case and padding' do
      expect(scheme.errors).to be_empty
    end
  end

  context 'with a well without its tag set' do
    let(:samples) { [sample(0, dual_index_tag_well: 'A1')] }

    it 'reports the well' do
      expect(scheme.errors).to eq(
        [{ pointer: pointer(0, 'dual_index_tag_well'),
           detail: 'dual_index_tag_well needs a dual_index_tag_set' }]
      )
    end
  end

  context 'with a tag set that does not exist, named by several samples' do
    let(:samples) do
      [sample(0, dual_index_tag_set: 'Unknown', dual_index_tag_well: 'A1'),
       sample(1, dual_index_tag_set: 'Unknown', dual_index_tag_well: 'B1')]
    end

    it 'reports it once, at its first sample' do
      expect(scheme.errors).to eq(
        [{ pointer: pointer(0, 'dual_index_tag_set'),
           detail: 'No visible dual index tag set named Unknown ' \
                   '(used by 2 samples)' }]
      )
    end
  end

  context 'with a single index tag set' do
    let(:single) do
      create(:tag_set, tag_group: create(:tag_group_with_tags, tag_count: 2),
                       tag2_group: nil)
    end
    let(:samples) do
      [sample(0, dual_index_tag_set: single.name, dual_index_tag_well: 'A1')]
    end

    it 'reports the tag set' do
      expect(scheme.errors.sole[:pointer])
        .to eq(pointer(0, 'dual_index_tag_set'))
    end
  end

  context 'with a tag set whose tag 2 group is hidden' do
    let(:samples) do
      [sample(0, dual_index_tag_set: tag_set.name, dual_index_tag_well: 'A1')]
    end

    before { tag_set.tag2_group.update!(visible: false) }

    it 'reports the tag set' do
      expect(scheme.errors.sole[:pointer])
        .to eq(pointer(0, 'dual_index_tag_set'))
    end
  end

  %w[I1 A13 X].each do |well|
    context "with #{well} as the well" do
      let(:samples) do
        [sample(0, dual_index_tag_set: tag_set.name,
                   dual_index_tag_well: well)]
      end

      it 'reports the well' do
        expect(scheme.errors).to eq(
          [{ pointer: pointer(0, 'dual_index_tag_well'),
             detail: "#{well} is not a well of a 96-well plate" }]
        )
      end
    end
  end

  context 'with a well whose i7 and i5 tags are missing' do
    let(:samples) do
      [sample(0, dual_index_tag_set: tag_set.name, dual_index_tag_well: 'C1'),
       sample(1, dual_index_tag_set: tag_set.name, dual_index_tag_well: 'C1')]
    end

    it 'reports each tag once, at its first sample' do
      expect(scheme.errors.pluck(:detail)).to eq(
        ["Dual index tag set #{tag_set.name} has no i7 tag for well C1 " \
         '(used by 2 samples)',
         "Dual index tag set #{tag_set.name} has no i5 tag for well C1 " \
         '(used by 2 samples)']
      )
    end
  end

  context 'with a well whose i5 tag is missing' do
    let(:samples) do
      [sample(0, dual_index_tag_set: tag_set.name, dual_index_tag_well: 'B1')]
    end

    before { tag_set.tag2_group.tags.find_by(map_id: 2).destroy! }

    it 'reports the i5 tag' do
      expect(scheme.errors.sole[:detail])
        .to eq("Dual index tag set #{tag_set.name} has no i5 tag for well " \
               'B1 (used by 1 sample)')
    end
  end

  context 'with a sample sharing its receptacle' do
    let(:samples) do
      [sample(0, dual_index_tag_set: tag_set.name, dual_index_tag_well: 'A1')]
    end
    let(:other) do
      sample(1).with(pointer: '/labware/0/receptacles/0/samples/1')
    end
    let(:labware) { [plate_with([[samples.first, other]])] }

    it 'reports the receptacle' do
      expect(scheme.errors).to eq(
        [{ pointer: '/labware/0/receptacles/0',
           detail: 'A receptacle with dual index tags holds one sample, ' \
                   'not 2' }]
      )
    end
  end

  describe '#oligos' do
    let(:samples) do
      [sample(0, dual_index_tag_set: tag_set.name, dual_index_tag_well: 'b1')]
    end

    it 'gives the oligos of the i7 and i5 tags of the well, for one aliquot' do
      expect(scheme.oligos(samples.first)).to eq(
        [[tag_set.tag_group.tags.find_by(map_id: 2).oligo,
          tag_set.tag2_group.tags.find_by(map_id: 2).oligo]]
      )
    end
  end
end
