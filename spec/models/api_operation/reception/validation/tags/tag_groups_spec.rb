# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::Reception::Validation::Tags::TagGroups do
  subject(:scheme) { described_class.new(samples, input) }

  let(:input) do
    ApiOperation::Reception::Validation::Input.new(
      payload_labware: [], new_labware: [], new_samples: samples
    )
  end

  let(:tag_group) { create(:tag_group_with_tags, tag_count: 3) }
  let(:tag2_group) { create(:tag_group_with_tags, tag_count: 3) }

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

  # The pointer to a field of the sample in the receptacle at the index
  def pointer(index, field)
    "/labware/0/receptacles/#{index}/samples/0/#{field}"
  end

  context 'with tags in existing groups' do
    let(:samples) do
      [sample(0, tag_group: tag_group.name, tag_index: 1,
                 tag2_group: tag2_group.name, tag2_index: 3),
       sample(1, tag_group: tag_group.name, tag_index: 2)]
    end

    it 'finds no errors' do
      expect(scheme.errors).to be_empty
    end
  end

  context 'with a group named in another case' do
    let(:samples) do
      [sample(0, tag_group: tag_group.name.upcase, tag_index: 1)]
    end

    it 'finds no errors' do
      expect(scheme.errors).to be_empty
    end
  end

  context 'with a group without its index' do
    let(:samples) { [sample(0, tag_group: tag_group.name)] }

    it 'reports the group' do
      expect(scheme.errors).to eq(
        [{ pointer: pointer(0, 'tag_group'),
           detail: 'tag_group needs a tag_index' }]
      )
    end
  end

  context 'with an index without its group' do
    let(:samples) { [sample(0, tag2_index: 1)] }

    it 'reports the index' do
      expect(scheme.errors).to eq(
        [{ pointer: pointer(0, 'tag2_index'),
           detail: 'tag2_index needs a tag2_group' }]
      )
    end
  end

  context 'with a group that does not exist, named by several samples' do
    let(:samples) do
      [sample(0, tag_group: 'Unknown', tag_index: 1),
       sample(1, tag_group: 'Unknown', tag_index: 2)]
    end

    it 'reports it once, at its first sample' do
      expect(scheme.errors).to eq(
        [{ pointer: pointer(0, 'tag_group'),
           detail: 'No tag group named Unknown (used by 2 samples)' }]
      )
    end
  end

  context 'with an index the group has no tag at' do
    let(:samples) do
      [sample(0, tag_group: tag_group.name, tag_index: 4),
       sample(1, tag_group: tag_group.name, tag_index: 4)]
    end

    it 'reports it once, at its first sample' do
      expect(scheme.errors).to eq(
        [{ pointer: pointer(0, 'tag_index'),
           detail: "Tag group #{tag_group.name} has no tag with index 4 " \
                   '(used by 2 samples)' }]
      )
    end
  end

  context 'with a tag 2 index the group has no tag at' do
    let(:samples) do
      [sample(0, tag_group: tag_group.name, tag_index: 1,
                 tag2_group: tag2_group.name, tag2_index: 9)]
    end

    it 'reports tag 2' do
      expect(scheme.errors.sole[:pointer]).to eq(pointer(0, 'tag2_index'))
    end
  end

  context 'with a tag that is in another group' do
    let(:other_group) { create(:tag_group_with_tags, tag_count: 5) }
    let(:samples) do
      [sample(0, tag_group: tag_group.name, tag_index: 5),
       sample(1, tag_group: other_group.name, tag_index: 5)]
    end

    it 'reports only the group without it' do
      expect(scheme.errors.sole[:pointer]).to eq(pointer(0, 'tag_index'))
    end
  end

  context 'with many samples in several groups' do
    let(:groups) { create_list(:tag_group_with_tags, 3, tag_count: 2) }
    let(:samples) do
      groups.each_with_index.map do |group, index|
        sample(index, tag_group: group.name, tag_index: 2)
      end
    end

    # Built first, so creating the groups isn't counted
    before { samples }

    it 'looks them up in two queries' do
      expect(queries_in { scheme.errors }.size).to eq(2)
    end
  end

  # The SQL queries the block runs
  def queries_in(&)
    queries = []
    count = ->(*, payload) { queries << payload[:sql] }
    ActiveSupport::Notifications.subscribed(count, 'sql.active_record', &)
    queries
  end

  describe '#oligos' do
    let(:samples) do
      [sample(0, tag_group: tag_group.name, tag_index: 2,
                 tag2_group: tag2_group.name.upcase, tag2_index: 3),
       sample(1, tag_group: tag_group.name, tag_index: 1)]
    end

    def oligo(group, index)
      group.tags.find_by(map_id: index).oligo
    end

    it 'gives the oligos of the tag and tag 2, for one aliquot' do
      expect(scheme.oligos(samples.first))
        .to eq([[oligo(tag_group, 2), oligo(tag2_group, 3)]])
    end

    it 'gives nil for a tag 2 not given' do
      expect(scheme.oligos(samples.last))
        .to eq([[oligo(tag_group, 1), nil]])
    end
  end
end
