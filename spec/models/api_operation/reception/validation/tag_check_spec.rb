# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::Reception::Validation::TagCheck do
  subject(:check) { described_class.new(input) }

  let(:input) do
    ApiOperation::Reception::Validation::Input.new(
      payload_labware: [], new_labware: [], new_samples: samples
    )
  end

  # A sample in the receptacle at the index, with the tag fields
  def sample(index, **fields)
    ApiOperation::Reception::Payload::PayloadSample.new(
      uuid: SecureRandom.uuid, study_uuid: SecureRandom.uuid,
      sanger_sample_id: "SAMPLE-#{index}",
      supplier_sample_name: "Supplier sample #{index}",
      fields: fields.stringify_keys,
      pointer: "/labware/0/receptacles/#{index}/samples/0"
    )
  end

  context 'with samples without tags' do
    let(:samples) { [sample(0), sample(1)] }

    it 'finds no errors' do
      expect(check.errors).to be_empty
    end
  end

  context 'with samples that give their tags one way' do
    let(:samples) do
      [sample(0, i7: 'ACGT', i5: 'TTGA'), sample(1, i7: 'GGCC')]
    end

    it 'finds no errors' do
      expect(check.errors).to be_empty
    end
  end

  context 'with a sample that gives its tags in more than one way' do
    let(:samples) do
      [sample(0, i7: 'ACGT', tag_group: 'Group 1', tag_index: 1)]
    end

    it 'reports the sample and the ways' do
      expect(check.errors).to eq(
        [{ pointer: '/labware/0/receptacles/0/samples/0',
           detail: 'Sample SAMPLE-0 gives its tags in more than one way: ' \
                   'i7/i5 and tag group and index' }]
      )
    end
  end

  context 'with a mixed sample whose fields have problems too' do
    let(:samples) { [sample(0, i7: 'NOT AN OLIGO', chromium_tag_well: 'A1')] }

    it 'reports only that it is mixed' do
      expect(check.errors.sole[:pointer])
        .to eq('/labware/0/receptacles/0/samples/0')
    end
  end

  context 'with a sample whose scheme finds a problem' do
    let(:samples) { [sample(0, i7: 'ACGX')] }

    it 'reports it' do
      expect(check.errors.sole[:pointer])
        .to eq('/labware/0/receptacles/0/samples/0/i7')
    end
  end

  context 'with a sample in two receptacles with different tags' do
    let(:first) { sample(0, i7: 'ACGT') }
    let(:samples) do
      [first,
       first.with(fields: { 'i7' => 'TTTT' },
                  pointer: '/labware/0/receptacles/1/samples/0')]
    end

    it 'finds no errors' do
      expect(check.errors).to be_empty
    end
  end

  describe 'tag clashes' do
    let(:input) do
      ApiOperation::Reception::Validation::Input.build(labware, labware)
    end
    let(:samples) { [] }
    let(:tag_group) { create(:tag_group_with_tags, tag_count: 2) }

    # A sample entry in a receptacle, with tag fields
    def entry(receptacle, index, uuid: SecureRandom.uuid, **fields)
      ApiOperation::Reception::Payload::PayloadSample.new(
        uuid: uuid, study_uuid: SecureRandom.uuid,
        sanger_sample_id: "SAMPLE-#{receptacle}-#{index}",
        supplier_sample_name: 'Supplier sample',
        fields: fields.stringify_keys,
        pointer: "/labware/0/receptacles/#{receptacle}/samples/#{index}"
      )
    end

    # A plate with a well for each list of samples, A1 onwards
    def plate_with(*samples_by_well)
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

    context 'with different tags in a receptacle' do
      let(:labware) do
        [plate_with([entry(0, 0, i7: 'ACGT', i5: 'TTGA'),
                     entry(0, 1, i7: 'ACGT', i5: 'GGCC')])]
      end

      it 'finds no errors' do
        expect(check.errors).to be_empty
      end
    end

    context 'with the same tags in a receptacle, in another case' do
      let(:labware) do
        [plate_with([entry(0, 0, i7: 'ACGT', i5: 'TTGA'),
                     entry(0, 1, i7: 'acgt', i5: 'ttga')])]
      end

      it 'reports the clash at the receptacle, naming the samples' do
        expect(check.errors).to eq(
          [{ pointer: '/labware/0/receptacles/0',
             detail: 'The same tags (i7 ACGT, i5 TTGA) are given for ' \
                     '/labware/0/receptacles/0/samples/0 and ' \
                     '/labware/0/receptacles/0/samples/1' }]
        )
      end
    end

    context 'with the same tags in different receptacles' do
      let(:labware) do
        [plate_with([entry(0, 0, i7: 'ACGT')], [entry(1, 0, i7: 'ACGT')])]
      end

      it 'finds no errors' do
        expect(check.errors).to be_empty
      end
    end

    context 'with the same oligo as an i7 and as an i5' do
      let(:labware) do
        [plate_with([entry(0, 0, i7: 'ACGT'), entry(0, 1, i5: 'ACGT')])]
      end

      it 'finds no errors' do
        expect(check.errors).to be_empty
      end
    end

    context 'with a tag group tag and an i7 with the same oligo' do
      let(:oligo) { tag_group.tags.find_by(map_id: 1).oligo }
      let(:labware) do
        [plate_with([entry(0, 0, tag_group: tag_group.name, tag_index: 1),
                     entry(0, 1, i7: oligo)])]
      end

      it 'reports the clash' do
        expect(check.errors.sole[:detail])
          .to start_with("The same tags (i7 #{oligo}) are given for")
      end
    end

    context 'with untagged samples in a receptacle' do
      let(:labware) { [plate_with([entry(0, 0), entry(0, 1)])] }

      it 'finds no errors, as they are a pool' do
        expect(check.errors).to be_empty
      end
    end

    context 'with tagged and untagged samples in a receptacle' do
      let(:labware) do
        [plate_with([entry(0, 0, i7: 'ACGT'), entry(0, 1)])]
      end

      it 'finds no errors' do
        expect(check.errors).to be_empty
      end
    end

    context 'with a sample in a receptacle twice, with different tags' do
      let(:uuid) { SecureRandom.uuid }
      let(:labware) do
        [plate_with([entry(0, 0, uuid: uuid, i7: 'ACGT'),
                     entry(0, 1, uuid: uuid, i7: 'TTGA')])]
      end

      it 'finds no errors' do
        expect(check.errors).to be_empty
      end
    end

    context 'with a receptacle with a tag problem' do
      let(:labware) do
        [plate_with([entry(0, 0, tag_group: 'Unknown', tag_index: 1),
                     entry(0, 1, i7: 'ACGT'), entry(0, 2, i7: 'ACGT')])]
      end

      it 'reports only the tag problem' do
        expect(check.errors.sole[:pointer])
          .to eq('/labware/0/receptacles/0/samples/0/tag_group')
      end
    end

    context 'with a Chromium well whose tags share an oligo' do
      let(:chromium_group) do
        create(:tag_group,
               adapter_type: create(:adapter_type, name: 'Chromium'))
      end
      let(:tag_set) do
        create(:tag_set, tag_group: chromium_group, tag2_group: nil)
      end
      let(:labware) do
        [plate_with([entry(0, 0, chromium_tag_group: tag_set.name,
                                 chromium_tag_well: 'A1')])]
      end

      # The four tags of well A1, the first two with the same oligo
      before do
        %w[AAAC AAAC AAAT AAAA].each.with_index(1) do |oligo, map_id|
          create(:tag, tag_group: chromium_group, map_id: map_id, oligo: oligo)
        end
      end

      it 'reports the sample' do
        expect(check.errors.sole[:detail]).to eq(
          'The same tags (i7 AAAC) are given more than once for ' \
          '/labware/0/receptacles/0/samples/0'
        )
      end
    end
  end
end
