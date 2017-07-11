require 'rails_helper'

# Note: These tests JUST check the factory characteristic of layout
# templates. The actual layout of tags is carried out by the tag layouts themselves,
# and is tested there.
describe TagLayout do
  def generate_tag_layout(plate, tag_type = :tag)
    plate.wells.with_aliquots.each_with_object({}) do |w, h|
      h[w.map_description] = w.aliquots.map(&tag_type)
    end
  end

  let(:plate) { create :plate_with_untagged_wells, well_count: 16 }
  let(:tag_group) { create :tag_group, tag_count: tag_count }
  let(:tag2_group) { nil }
  let(:tag_count) { 16 }
  let(:user) { create :user }
  let(:initial_tag) { 0 }

  shared_examples 'a tag layout' do
    let(:expected_tags) do
      expected_tag_layout.transform_values do |map_ids|
        map_ids.map { |id| tag_group.tags.detect { |tag| tag.map_id == id } }
      end
    end
    it 'applies the expected layout' do
      expect(generate_tag_layout(plate)).to eq expected_tags
    end

    it 'updates the library_id of the wells' do
      plate.wells.with_aliquots.each do |well|
        expect(well.aliquots.first.library_id).to eq well.id
      end
    end
  end

  context 'substitutions' do
    let(:tag_layout) { create :tag_layout }
    it 'defaults to an empty hash' do
      expect(tag_layout.substitutions).to eq({})
    end
  end

  context 'layouts' do
    before do
      create(:tag_layout,
             plate: plate,
             user: user,
             tag_group: tag_group,
             tag2_group: tag2_group,
             walking_by: walking_by,
             direction: direction,
             initial_tag: initial_tag)
    end

    context 'by_column' do
      let(:direction) { 'column' }

      context 'manual by plate' do
        let(:walking_by) { 'manual by plate' }

        context 'with a full plate' do
          let(:expected_tag_layout) do
            { 'A1' => [1], 'B1' => [2], 'C1' => [3], 'D1' => [4], 'E1' => [5], 'F1' => [6], 'G1' => [7], 'H1' => [8] }
          end
          it_behaves_like 'a tag layout'
        end

        context 'with a partial plate' do
          setup do
            plate.wells.located_at('B1').first.aliquots.clear
          end
          let(:expected_tag_layout) do
            { 'A1' => [1], 'C1' => [3], 'D1' => [4], 'E1' => [5], 'F1' => [6], 'G1' => [7], 'H1' => [8] }
          end
          it_behaves_like 'a tag layout'
        end
      end

      context 'wells of plate' do
        let(:walking_by) { 'wells of plate' }

        context 'with a full plate' do
          let(:expected_tag_layout) do
            { 'A1' => [1], 'B1' => [2], 'C1' => [3], 'D1' => [4], 'E1' => [5], 'F1' => [6], 'G1' => [7], 'H1' => [8] }
          end
          it_behaves_like 'a tag layout'
        end

        context 'with a partial plate' do
          before { plate.wells.located_at('B1').first.aliquots.clear }

          let(:expected_tag_layout) do
            { 'A1' => [1], 'C1' => [3], 'D1' => [4], 'E1' => [5], 'F1' => [6], 'G1' => [7], 'H1' => [8] }
          end
          it_behaves_like 'a tag layout'
        end
      end

      context 'grouped by plate' do
        let(:walking_by) { 'as group by plate' }
        let(:tag_count) { 32 }

        context 'with no offset' do
          let(:expected_tag_layout) do
            { 'A1' => [1, 2, 3, 4], 'B1' => [5, 6, 7, 8], 'C1' => [9, 10, 11, 12], 'D1' => [13, 14, 15, 16], 'E1' => [17, 18, 19, 20], 'F1' => [21, 22, 23, 24], 'G1' => [25, 26, 27, 28], 'H1' => [29, 30, 31, 32] }
          end
          it_behaves_like 'a tag layout'
        end

        context 'with an initial_tag' do
          let(:initial_tag) { 4 }

          let(:expected_tag_layout) do
            { 'H1' => [1, 2, 3, 4], 'A1' => [5, 6, 7, 8], 'B1' => [9, 10, 11, 12], 'C1' => [13, 14, 15, 16], 'D1' => [17, 18, 19, 20], 'E1' => [21, 22, 23, 24], 'F1' => [25, 26, 27, 28], 'G1' => [29, 30, 31, 32] }
          end
          it_behaves_like 'a tag layout'
        end
      end
    end

    context 'inverted layout' do
      let(:direction) { 'inverse column' }
      let(:walking_by) { 'wells of plate' }
      let(:expected_tag_layout) do
        { 'A1' => [8], 'B1' => [7], 'C1' => [6], 'D1' => [5], 'E1' => [4], 'F1' => [3], 'G1' => [2], 'H1' => [1] }
      end
      it_behaves_like 'a tag layout'
    end

    context 'with a tag2 group' do
      let(:tag2_group) { create :tag_group, tag_count: tag_count }
      let(:walking_by) { 'wells of plate' }
      let(:direction) { 'column' }
      let(:expected_tag_layout) do
        { 'A1' => [1], 'B1' => [2], 'C1' => [3], 'D1' => [4], 'E1' => [5], 'F1' => [6], 'G1' => [7], 'H1' => [8] }
      end
      let(:expected_tag2s) do
        # We use the same tag indicies, just from a different tag group
        expected_tag_layout.transform_values do |map_ids|
          map_ids.map { |id| tag2_group.tags.detect { |tag| tag.map_id == id } }
        end
      end
      it 'applies the expected tag2 layout' do
        expect(generate_tag_layout(plate, :tag2)).to eq expected_tag2s
      end
    end
  end
end
