# frozen_string_literal: true

require 'rails_helper'

# NOTE: These tests JUST check the factory characteristic of layout
# templates. The actual layout of tags is carried out by the tag layouts themselves,
# and is tested there.
describe TagLayout do
  def generate_tag_layout(plate, tag_type = :tag)
    plate.wells.with_aliquots.each_with_object({}) { |w, h| h[w.map_description] = w.aliquots.map(&tag_type) }
  end

  let(:plate) { create :plate_with_untagged_wells, well_count: 8 }
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
      plate.wells.with_aliquots.each { |well| expect(well.aliquots.first.library_id).to eq well.id }
    end
  end

  context 'substitutions' do
    let(:tag_layout) { build_stubbed :tag_layout }

    it 'defaults to an empty hash' do
      expect(tag_layout.substitutions).to eq({})
    end
  end

  context 'layouts' do
    before do
      create(
        :tag_layout,
        plate: plate,
        user: user,
        tag_group: tag_group,
        tag2_group: tag2_group,
        walking_by: walking_by,
        direction: direction,
        initial_tag: initial_tag
      )
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
          before { plate.wells.located_at('B1').first.aliquots.clear }

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

      context 'combinatorial sequential' do
        let(:walking_by) { 'combinatorial sequential' }

        context 'with row directions' do
          let(:direction) { 'combinatorial by row' }

          context 'with a 384 well plate' do
            let(:plate) { create :plate_with_untagged_wells, sample_count: 4 * 16, size: 384 }
            let(:tag_count) { 384 }
            let(:tag2_group) { create :tag_group, tag_count: tag_count }
            let(:expected_tag_layout) do
              {
                'A1' => [1],
                'A2' => [1],
                'A3' => [1],
                'A4' => [1],
                'B1' => [2],
                'B2' => [2],
                'B3' => [2],
                'B4' => [2],
                'C1' => [3],
                'C2' => [3],
                'C3' => [3],
                'C4' => [3],
                'D1' => [4],
                'D2' => [4],
                'D3' => [4],
                'D4' => [4],
                'E1' => [5],
                'E2' => [5],
                'E3' => [5],
                'E4' => [5],
                'F1' => [6],
                'F2' => [6],
                'F3' => [6],
                'F4' => [6],
                'G1' => [7],
                'G2' => [7],
                'G3' => [7],
                'G4' => [7],
                'H1' => [8],
                'H2' => [8],
                'H3' => [8],
                'H4' => [8],
                'I1' => [9],
                'I2' => [9],
                'I3' => [9],
                'I4' => [9],
                'J1' => [10],
                'J2' => [10],
                'J3' => [10],
                'J4' => [10],
                'K1' => [11],
                'K2' => [11],
                'K3' => [11],
                'K4' => [11],
                'L1' => [12],
                'L2' => [12],
                'L3' => [12],
                'L4' => [12],
                'M1' => [13],
                'M2' => [13],
                'M3' => [13],
                'M4' => [13],
                'N1' => [14],
                'N2' => [14],
                'N3' => [14],
                'N4' => [14],
                'O1' => [15],
                'O2' => [15],
                'O3' => [15],
                'O4' => [15],
                'P1' => [16],
                'P2' => [16],
                'P3' => [16],
                'P4' => [16]
              }
            end
            let(:expected_tag2_layout) do
              {
                'A1' => [1],
                'A2' => [2],
                'A3' => [3],
                'A4' => [4],
                'B1' => [1],
                'B2' => [2],
                'B3' => [3],
                'B4' => [4],
                'C1' => [1],
                'C2' => [2],
                'C3' => [3],
                'C4' => [4],
                'D1' => [1],
                'D2' => [2],
                'D3' => [3],
                'D4' => [4],
                'E1' => [1],
                'E2' => [2],
                'E3' => [3],
                'E4' => [4],
                'F1' => [1],
                'F2' => [2],
                'F3' => [3],
                'F4' => [4],
                'G1' => [1],
                'G2' => [2],
                'G3' => [3],
                'G4' => [4],
                'H1' => [1],
                'H2' => [2],
                'H3' => [3],
                'H4' => [4],
                'I1' => [1],
                'I2' => [2],
                'I3' => [3],
                'I4' => [4],
                'J1' => [1],
                'J2' => [2],
                'J3' => [3],
                'J4' => [4],
                'K1' => [1],
                'K2' => [2],
                'K3' => [3],
                'K4' => [4],
                'L1' => [1],
                'L2' => [2],
                'L3' => [3],
                'L4' => [4],
                'M1' => [1],
                'M2' => [2],
                'M3' => [3],
                'M4' => [4],
                'N1' => [1],
                'N2' => [2],
                'N3' => [3],
                'N4' => [4],
                'O1' => [1],
                'O2' => [2],
                'O3' => [3],
                'O4' => [4],
                'P1' => [1],
                'P2' => [2],
                'P3' => [3],
                'P4' => [4]
              }
            end
            let(:expected_tag2s) do
              expected_tag2_layout.transform_values do |map_ids|
                map_ids.map { |id| tag2_group.tags.detect { |tag| tag.map_id == id } }
              end
            end

            it_behaves_like 'a tag layout'

            it 'applies the expected tag2 layout' do
              expect(generate_tag_layout(plate, :tag2)).to eq expected_tag2s
            end
          end
        end
      end

      context 'quadrants' do
        let(:walking_by) { 'quadrants' }

        context 'with column then row directions' do
          let(:direction) { 'column then row' }

          context 'with a 384 well plate' do
            let(:plate) { create :plate_with_untagged_wells, sample_count: 4 * 16, size: 384 }
            let(:tag_count) { 384 }
            let(:tag2_group) { create :tag_group, tag_count: tag_count }
            let(:expected_tag_layout) do
              {
                'A1' => [1],
                'A2' => [1],
                'A3' => [9],
                'A4' => [9],
                'B1' => [1],
                'B2' => [1],
                'B3' => [9],
                'B4' => [9],
                'C1' => [2],
                'C2' => [2],
                'C3' => [10],
                'C4' => [10],
                'D1' => [2],
                'D2' => [2],
                'D3' => [10],
                'D4' => [10],
                'E1' => [3],
                'E2' => [3],
                'E3' => [11],
                'E4' => [11],
                'F1' => [3],
                'F2' => [3],
                'F3' => [11],
                'F4' => [11],
                'G1' => [4],
                'G2' => [4],
                'G3' => [12],
                'G4' => [12],
                'H1' => [4],
                'H2' => [4],
                'H3' => [12],
                'H4' => [12],
                'I1' => [5],
                'I2' => [5],
                'I3' => [13],
                'I4' => [13],
                'J1' => [5],
                'J2' => [5],
                'J3' => [13],
                'J4' => [13],
                'K1' => [6],
                'K2' => [6],
                'K3' => [14],
                'K4' => [14],
                'L1' => [6],
                'L2' => [6],
                'L3' => [14],
                'L4' => [14],
                'M1' => [7],
                'M2' => [7],
                'M3' => [15],
                'M4' => [15],
                'N1' => [7],
                'N2' => [7],
                'N3' => [15],
                'N4' => [15],
                'O1' => [8],
                'O2' => [8],
                'O3' => [16],
                'O4' => [16],
                'P1' => [8],
                'P2' => [8],
                'P3' => [16],
                'P4' => [16]
              }
            end
            let(:expected_tag2_layout) do
              {
                'A1' => [1],
                'A2' => [2],
                'A3' => [1],
                'A4' => [2],
                'B1' => [3],
                'B2' => [4],
                'B3' => [3],
                'B4' => [4],
                'C1' => [1],
                'C2' => [2],
                'C3' => [1],
                'C4' => [2],
                'D1' => [3],
                'D2' => [4],
                'D3' => [3],
                'D4' => [4],
                'E1' => [1],
                'E2' => [2],
                'E3' => [1],
                'E4' => [2],
                'F1' => [3],
                'F2' => [4],
                'F3' => [3],
                'F4' => [4],
                'G1' => [1],
                'G2' => [2],
                'G3' => [1],
                'G4' => [2],
                'H1' => [3],
                'H2' => [4],
                'H3' => [3],
                'H4' => [4],
                'I1' => [1],
                'I2' => [2],
                'I3' => [1],
                'I4' => [2],
                'J1' => [3],
                'J2' => [4],
                'J3' => [3],
                'J4' => [4],
                'K1' => [1],
                'K2' => [2],
                'K3' => [1],
                'K4' => [2],
                'L1' => [3],
                'L2' => [4],
                'L3' => [3],
                'L4' => [4],
                'M1' => [1],
                'M2' => [2],
                'M3' => [1],
                'M4' => [2],
                'N1' => [3],
                'N2' => [4],
                'N3' => [3],
                'N4' => [4],
                'O1' => [1],
                'O2' => [2],
                'O3' => [1],
                'O4' => [2],
                'P1' => [3],
                'P2' => [4],
                'P3' => [3],
                'P4' => [4]
              }
            end
            let(:expected_tag2s) do
              expected_tag2_layout.transform_values do |map_ids|
                map_ids.map { |id| tag2_group.tags.detect { |tag| tag.map_id == id } }
              end
            end

            it_behaves_like 'a tag layout'

            it 'applies the expected tag2 layout' do
              expect(generate_tag_layout(plate, :tag2)).to eq expected_tag2s
            end
          end
        end

        context 'with column directions' do
          let(:direction) { 'column' }

          context 'with a 384 well plate' do
            let(:plate) { create :plate_with_untagged_wells, sample_count: 4 * 16, size: 384 }
            let(:tag_count) { 384 }
            let(:tag2_group) { create :tag_group, tag_count: tag_count }
            let(:expected_tag_layout) do
              {
                'A1' => [1],
                'A2' => [1],
                'A3' => [9],
                'A4' => [9],
                'B1' => [1],
                'B2' => [1],
                'B3' => [9],
                'B4' => [9],
                'C1' => [2],
                'C2' => [2],
                'C3' => [10],
                'C4' => [10],
                'D1' => [2],
                'D2' => [2],
                'D3' => [10],
                'D4' => [10],
                'E1' => [3],
                'E2' => [3],
                'E3' => [11],
                'E4' => [11],
                'F1' => [3],
                'F2' => [3],
                'F3' => [11],
                'F4' => [11],
                'G1' => [4],
                'G2' => [4],
                'G3' => [12],
                'G4' => [12],
                'H1' => [4],
                'H2' => [4],
                'H3' => [12],
                'H4' => [12],
                'I1' => [5],
                'I2' => [5],
                'I3' => [13],
                'I4' => [13],
                'J1' => [5],
                'J2' => [5],
                'J3' => [13],
                'J4' => [13],
                'K1' => [6],
                'K2' => [6],
                'K3' => [14],
                'K4' => [14],
                'L1' => [6],
                'L2' => [6],
                'L3' => [14],
                'L4' => [14],
                'M1' => [7],
                'M2' => [7],
                'M3' => [15],
                'M4' => [15],
                'N1' => [7],
                'N2' => [7],
                'N3' => [15],
                'N4' => [15],
                'O1' => [8],
                'O2' => [8],
                'O3' => [16],
                'O4' => [16],
                'P1' => [8],
                'P2' => [8],
                'P3' => [16],
                'P4' => [16]
              }
            end
            let(:expected_tag2_layout) do
              {
                'A1' => [1],
                'A2' => [1],
                'A3' => [9],
                'A4' => [9],
                'B1' => [1],
                'B2' => [1],
                'B3' => [9],
                'B4' => [9],
                'C1' => [2],
                'C2' => [2],
                'C3' => [10],
                'C4' => [10],
                'D1' => [2],
                'D2' => [2],
                'D3' => [10],
                'D4' => [10],
                'E1' => [3],
                'E2' => [3],
                'E3' => [11],
                'E4' => [11],
                'F1' => [3],
                'F2' => [3],
                'F3' => [11],
                'F4' => [11],
                'G1' => [4],
                'G2' => [4],
                'G3' => [12],
                'G4' => [12],
                'H1' => [4],
                'H2' => [4],
                'H3' => [12],
                'H4' => [12],
                'I1' => [5],
                'I2' => [5],
                'I3' => [13],
                'I4' => [13],
                'J1' => [5],
                'J2' => [5],
                'J3' => [13],
                'J4' => [13],
                'K1' => [6],
                'K2' => [6],
                'K3' => [14],
                'K4' => [14],
                'L1' => [6],
                'L2' => [6],
                'L3' => [14],
                'L4' => [14],
                'M1' => [7],
                'M2' => [7],
                'M3' => [15],
                'M4' => [15],
                'N1' => [7],
                'N2' => [7],
                'N3' => [15],
                'N4' => [15],
                'O1' => [8],
                'O2' => [8],
                'O3' => [16],
                'O4' => [16],
                'P1' => [8],
                'P2' => [8],
                'P3' => [16],
                'P4' => [16]
              }
            end
            let(:expected_tag2s) do
              expected_tag2_layout.transform_values do |map_ids|
                map_ids.map { |id| tag2_group.tags.detect { |tag| tag.map_id == id } }
              end
            end

            it_behaves_like 'a tag layout'

            it 'applies the expected tag2 layout' do
              expect(generate_tag_layout(plate, :tag2)).to eq expected_tag2s
            end
          end
        end

        context 'with inverse column directions' do
          let(:direction) { 'inverse column' }

          context 'with a 384 well plate' do
            let(:plate) { create :plate_with_untagged_wells, sample_count: 4 * 16, size: 384 }
            let(:tag_count) { 384 }
            let(:tag2_group) { create :tag_group, tag_count: tag_count }
            let(:expected_tag_layout) do
              {
                'A1' => [96],
                'A2' => [96],
                'A3' => [88],
                'A4' => [88],
                'B1' => [96],
                'B2' => [96],
                'B3' => [88],
                'B4' => [88],
                'C1' => [95],
                'C2' => [95],
                'C3' => [87],
                'C4' => [87],
                'D1' => [95],
                'D2' => [95],
                'D3' => [87],
                'D4' => [87],
                'E1' => [94],
                'E2' => [94],
                'E3' => [86],
                'E4' => [86],
                'F1' => [94],
                'F2' => [94],
                'F3' => [86],
                'F4' => [86],
                'G1' => [93],
                'G2' => [93],
                'G3' => [85],
                'G4' => [85],
                'H1' => [93],
                'H2' => [93],
                'H3' => [85],
                'H4' => [85],
                'I1' => [92],
                'I2' => [92],
                'I3' => [84],
                'I4' => [84],
                'J1' => [92],
                'J2' => [92],
                'J3' => [84],
                'J4' => [84],
                'K1' => [91],
                'K2' => [91],
                'K3' => [83],
                'K4' => [83],
                'L1' => [91],
                'L2' => [91],
                'L3' => [83],
                'L4' => [83],
                'M1' => [90],
                'M2' => [90],
                'M3' => [82],
                'M4' => [82],
                'N1' => [90],
                'N2' => [90],
                'N3' => [82],
                'N4' => [82],
                'O1' => [89],
                'O2' => [89],
                'O3' => [81],
                'O4' => [81],
                'P1' => [89],
                'P2' => [89],
                'P3' => [81],
                'P4' => [81]
              }
            end
            let(:expected_tag2_layout) do
              {
                'A1' => [96],
                'A2' => [96],
                'A3' => [88],
                'A4' => [88],
                'B1' => [96],
                'B2' => [96],
                'B3' => [88],
                'B4' => [88],
                'C1' => [95],
                'C2' => [95],
                'C3' => [87],
                'C4' => [87],
                'D1' => [95],
                'D2' => [95],
                'D3' => [87],
                'D4' => [87],
                'E1' => [94],
                'E2' => [94],
                'E3' => [86],
                'E4' => [86],
                'F1' => [94],
                'F2' => [94],
                'F3' => [86],
                'F4' => [86],
                'G1' => [93],
                'G2' => [93],
                'G3' => [85],
                'G4' => [85],
                'H1' => [93],
                'H2' => [93],
                'H3' => [85],
                'H4' => [85],
                'I1' => [92],
                'I2' => [92],
                'I3' => [84],
                'I4' => [84],
                'J1' => [92],
                'J2' => [92],
                'J3' => [84],
                'J4' => [84],
                'K1' => [91],
                'K2' => [91],
                'K3' => [83],
                'K4' => [83],
                'L1' => [91],
                'L2' => [91],
                'L3' => [83],
                'L4' => [83],
                'M1' => [90],
                'M2' => [90],
                'M3' => [82],
                'M4' => [82],
                'N1' => [90],
                'N2' => [90],
                'N3' => [82],
                'N4' => [82],
                'O1' => [89],
                'O2' => [89],
                'O3' => [81],
                'O4' => [81],
                'P1' => [89],
                'P2' => [89],
                'P3' => [81],
                'P4' => [81]
              }
            end
            let(:expected_tag2s) do
              expected_tag2_layout.transform_values do |map_ids|
                map_ids.map { |id| tag2_group.tags.detect { |tag| tag.map_id == id } }
              end
            end

            it_behaves_like 'a tag layout'

            it 'applies the expected tag2 layout' do
              expect(generate_tag_layout(plate, :tag2)).to eq expected_tag2s
            end
          end
        end

        context 'with row directions' do
          let(:direction) { 'row' }

          context 'with a 384 well plate' do
            let(:plate) { create :plate_with_untagged_wells, sample_count: 4 * 16, size: 384 }
            let(:tag_count) { 384 }
            let(:tag2_group) { create :tag_group, tag_count: tag_count }
            let(:expected_tag_layout) do
              {
                'A1' => [1],
                'A2' => [1],
                'A3' => [2],
                'A4' => [2],
                'B1' => [1],
                'B2' => [1],
                'B3' => [2],
                'B4' => [2],
                'C1' => [13],
                'C2' => [13],
                'C3' => [14],
                'C4' => [14],
                'D1' => [13],
                'D2' => [13],
                'D3' => [14],
                'D4' => [14],
                'E1' => [25],
                'E2' => [25],
                'E3' => [26],
                'E4' => [26],
                'F1' => [25],
                'F2' => [25],
                'F3' => [26],
                'F4' => [26],
                'G1' => [37],
                'G2' => [37],
                'G3' => [38],
                'G4' => [38],
                'H1' => [37],
                'H2' => [37],
                'H3' => [38],
                'H4' => [38],
                'I1' => [49],
                'I2' => [49],
                'I3' => [50],
                'I4' => [50],
                'J1' => [49],
                'J2' => [49],
                'J3' => [50],
                'J4' => [50],
                'K1' => [61],
                'K2' => [61],
                'K3' => [62],
                'K4' => [62],
                'L1' => [61],
                'L2' => [61],
                'L3' => [62],
                'L4' => [62],
                'M1' => [73],
                'M2' => [73],
                'M3' => [74],
                'M4' => [74],
                'N1' => [73],
                'N2' => [73],
                'N3' => [74],
                'N4' => [74],
                'O1' => [85],
                'O2' => [85],
                'O3' => [86],
                'O4' => [86],
                'P1' => [85],
                'P2' => [85],
                'P3' => [86],
                'P4' => [86]
              }
            end
            let(:expected_tag2_layout) do
              {
                'A1' => [1],
                'A2' => [1],
                'A3' => [2],
                'A4' => [2],
                'B1' => [1],
                'B2' => [1],
                'B3' => [2],
                'B4' => [2],
                'C1' => [13],
                'C2' => [13],
                'C3' => [14],
                'C4' => [14],
                'D1' => [13],
                'D2' => [13],
                'D3' => [14],
                'D4' => [14],
                'E1' => [25],
                'E2' => [25],
                'E3' => [26],
                'E4' => [26],
                'F1' => [25],
                'F2' => [25],
                'F3' => [26],
                'F4' => [26],
                'G1' => [37],
                'G2' => [37],
                'G3' => [38],
                'G4' => [38],
                'H1' => [37],
                'H2' => [37],
                'H3' => [38],
                'H4' => [38],
                'I1' => [49],
                'I2' => [49],
                'I3' => [50],
                'I4' => [50],
                'J1' => [49],
                'J2' => [49],
                'J3' => [50],
                'J4' => [50],
                'K1' => [61],
                'K2' => [61],
                'K3' => [62],
                'K4' => [62],
                'L1' => [61],
                'L2' => [61],
                'L3' => [62],
                'L4' => [62],
                'M1' => [73],
                'M2' => [73],
                'M3' => [74],
                'M4' => [74],
                'N1' => [73],
                'N2' => [73],
                'N3' => [74],
                'N4' => [74],
                'O1' => [85],
                'O2' => [85],
                'O3' => [86],
                'O4' => [86],
                'P1' => [85],
                'P2' => [85],
                'P3' => [86],
                'P4' => [86]
              }
            end
            let(:expected_tag2s) do
              expected_tag2_layout.transform_values do |map_ids|
                map_ids.map { |id| tag2_group.tags.detect { |tag| tag.map_id == id } }
              end
            end

            it_behaves_like 'a tag layout'

            it 'applies the expected tag2 layout' do
              expect(generate_tag_layout(plate, :tag2)).to eq expected_tag2s
            end
          end
        end
      end

      context 'grouped by plate' do
        let(:walking_by) { 'as group by plate' }
        let(:tag_count) { 32 }

        context 'with no offset' do
          let(:expected_tag_layout) do
            {
              'A1' => [1, 2, 3, 4],
              'B1' => [5, 6, 7, 8],
              'C1' => [9, 10, 11, 12],
              'D1' => [13, 14, 15, 16],
              'E1' => [17, 18, 19, 20],
              'F1' => [21, 22, 23, 24],
              'G1' => [25, 26, 27, 28],
              'H1' => [29, 30, 31, 32]
            }
          end

          it_behaves_like 'a tag layout'
        end

        context 'with an initial_tag' do
          let(:initial_tag) { 4 }

          let(:expected_tag_layout) do
            {
              'H1' => [1, 2, 3, 4],
              'A1' => [5, 6, 7, 8],
              'B1' => [9, 10, 11, 12],
              'C1' => [13, 14, 15, 16],
              'D1' => [17, 18, 19, 20],
              'E1' => [21, 22, 23, 24],
              'F1' => [25, 26, 27, 28],
              'G1' => [29, 30, 31, 32]
            }
          end

          it_behaves_like 'a tag layout'
        end
      end

      context 'fixed group by plate' do
        let(:walking_by) { 'as fixed group by plate' }
        let(:tag_count) { 32 }

        context 'with no offset' do
          let(:expected_tag_layout) do
            {
              'A1' => [1, 2, 3, 4],
              'B1' => [5, 6, 7, 8],
              'C1' => [9, 10, 11, 12],
              'D1' => [13, 14, 15, 16],
              'E1' => [17, 18, 19, 20],
              'F1' => [21, 22, 23, 24],
              'G1' => [25, 26, 27, 28],
              'H1' => [29, 30, 31, 32]
            }
          end

          it_behaves_like 'a tag layout'
        end

        context 'with a partial plate' do
          before { plate.wells.located_at('B1').first.aliquots.clear }

          let(:expected_tag_layout) do
            {
              'A1' => [1, 2, 3, 4],
              'C1' => [9, 10, 11, 12],
              'D1' => [13, 14, 15, 16],
              'E1' => [17, 18, 19, 20],
              'F1' => [21, 22, 23, 24],
              'G1' => [25, 26, 27, 28],
              'H1' => [29, 30, 31, 32]
            }
          end

          it_behaves_like 'a tag layout'
        end

        context 'with an initial_tag' do
          let(:initial_tag) { 4 }

          let(:expected_tag_layout) do
            {
              'A1' => [5, 6, 7, 8],
              'B1' => [9, 10, 11, 12],
              'C1' => [13, 14, 15, 16],
              'D1' => [17, 18, 19, 20],
              'E1' => [21, 22, 23, 24],
              'F1' => [25, 26, 27, 28],
              'G1' => [29, 30, 31, 32],
              'H1' => [1, 2, 3, 4]
            }
          end

          it_behaves_like 'a tag layout'
        end

        context 'with a partial plate and initial tag' do
          before { plate.wells.located_at('B1').first.aliquots.clear }

          let(:initial_tag) { 4 }
          let(:expected_tag_layout) do
            {
              'A1' => [5, 6, 7, 8],
              'C1' => [13, 14, 15, 16],
              'D1' => [17, 18, 19, 20],
              'E1' => [21, 22, 23, 24],
              'F1' => [25, 26, 27, 28],
              'G1' => [29, 30, 31, 32],
              'H1' => [1, 2, 3, 4]
            }
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
