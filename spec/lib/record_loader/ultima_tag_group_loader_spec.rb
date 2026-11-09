# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/ultima_tag_group_loader'

RSpec.describe RecordLoader::UltimaTagGroupLoader, :loader, type: :model do
  def a_new_record_loader
    described_class.new(directory: test_directory, files: selected_files)
  end

  # Z number and well of each tag of the group, by the tag's map_id.
  def loaded_ultima_tags
    tag_group.tags.to_h do |tag|
      ultima_tag = tag.reload.ultima_tag
      [tag.map_id, [ultima_tag&.index_barcode_num,
                    ultima_tag&.barcode_plate_well]]
    end
  end

  subject(:record_loader) { a_new_record_loader }

  let(:test_directory) do
    Rails.root.join('spec/data/record_loader/ultima_tag_groups')
  end
  let!(:tag_group) do
    create(:tag_group, name: 'Ultima Spec Group', tag_count: 3)
  end
  let(:sparse_ultima_tags) do
    { 1 => %w[Z5001 A1], 2 => %w[Z5005 B1], 3 => %w[Z5014 C1] }
  end

  context 'with a tag group whose Z numbers have gaps' do
    let(:selected_files) { 'ultima_tag_groups_sparse' }

    it 'creates the Ultima data of the tag group' do
      record_loader.create!
      expect(tag_group.reload.ultima_tag_group.barcode_plate_num).to eq(5)
    end

    it 'creates the Ultima data of each tag as given' do
      record_loader.create!
      expect(loaded_ultima_tags).to eq(sparse_ultima_tags)
    end

    it 'is idempotent' do
      record_loader.create!
      expect { a_new_record_loader.create! }
        .not_to(change { [UltimaTagGroup.count, UltimaTag.count] })
    end

    context 'when some Ultima data exists already' do
      before do
        create(:ultima_tag_group, tag_group: tag_group, barcode_plate_num: 9)
        create(:ultima_tag, tag: tag_group.tags.first,
                            index_barcode_num: 'Z9999',
                            barcode_plate_well: 'H12')
        record_loader.create!
      end

      it 'keeps the tag group data' do
        expect(tag_group.reload.ultima_tag_group.barcode_plate_num).to eq(9)
      end

      it 'keeps the existing tag data and creates the missing' do
        expect(loaded_ultima_tags)
          .to eq(sparse_ultima_tags.merge(1 => %w[Z9999 H12]))
      end
    end
  end

  context 'with no plate number for the tag group' do
    let(:selected_files) { 'ultima_tag_groups_no_plate_num' }

    it 'creates the Ultima data of the tag group without a plate number' do
      record_loader.create!
      expect(tag_group.reload.ultima_tag_group.barcode_plate_num).to be_nil
    end

    it 'creates the Ultima data of each tag as given' do
      record_loader.create!
      expect(loaded_ultima_tags).to eq(sparse_ultima_tags)
    end
  end

  context 'with the tag group name given as name:' do
    let(:selected_files) { 'ultima_tag_groups_named' }

    it 'creates the Ultima data of the named tag group' do
      record_loader.create!
      expect(loaded_ultima_tags).to eq(sparse_ultima_tags)
    end
  end

  context 'when the map_ids are not those of the tag group' do
    let(:selected_files) { 'ultima_tag_groups_wrong_map_ids' }

    it 'raises, naming the missing and unknown map_ids' do
      expect { record_loader.create! }.to raise_error(
        StandardError,
        'Failed to create Ultima Spec Group due to: tag map_ids not ' \
        'given: [2, 3], not in the tag group: [4]'
      )
    end

    it 'creates nothing' do
      expect { suppress(StandardError) { record_loader.create! } }
        .not_to(change { [UltimaTagGroup.count, UltimaTag.count] })
    end
  end

  context 'when the tag group does not exist' do
    let(:selected_files) { 'ultima_tag_groups_unknown_group' }

    it 'raises' do
      expect { record_loader.create! }.to raise_error(
        StandardError,
        /Ultima Spec Unknown Group due to: Couldn't find TagGroup/
      )
    end
  end
end
