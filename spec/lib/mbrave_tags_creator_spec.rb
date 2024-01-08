# frozen_string_literal: true
require 'spec_helper'
require 'rake'
require 'mbrave_tags_creator'

describe MbraveTagsCreator do
  describe 'MbraveTagsCreator::create_tag_plates' do
    context 'when receiving the right arguments' do
      let(:tag_group_one) { create(:tag_group) }
      let(:tag_purpose) { create(:plate_purpose, name: 'Tag Plate') }
      let(:run_action) { described_class.process_create_tag_plates('test', 'v1') }
      let(:tag_group_two) { create(:tag_group) }

      before do
        create(:user, login: 'test')
        create(
          :lot_type,
          name: 'Pre Stamped Tags - 384',
          template_class: 'TagLayoutTemplate',
          target_purpose: tag_purpose
        )

        create(
          :tag_layout_template,
          name: 'Bioscan_384_template_1_v1',
          tag_group: tag_group_one,
          tag2_group: tag_group_two
        )
        create(:tag_layout_template, name: 'bubidi_2_v1', tag_group: tag_group_one, tag2_group: tag_group_two)
        create(
          :tag_layout_template,
          name: 'Bioscan_384_template_3_v1',
          tag_group: tag_group_one,
          tag2_group: tag_group_two
        )
        create(
          :tag_layout_template,
          name: 'Bioscan_384_template_4_v14',
          tag_group: tag_group_one,
          tag2_group: tag_group_two
        )
        create(
          :tag_layout_template,
          name: 'Bioscan_384_template_5_v1',
          tag_group: tag_group_one,
          tag2_group: tag_group_two
        )

        allow(PlateBarcode).to receive(:create_barcode_with_text).and_return(build(:plate_barcode))
      end

      it 'creates tag plates' do
        expect { run_action }.to change(Plate, :count).by(3)
      end
    end
  end

  describe 'MbraveTagsCreator::create_tag_groups' do
    context 'when there is valid arguments' do
      let(:forward_file) do
        file = Tempfile.new('forward')
        file.write(
          [
            'Forward Index Number,Forward Oligo Label,F index sequence',
            '1,PB1F_bc1001,CACATATCAGAGTGCG',
            '2,PB1F_bc1002,ACACACAGACTGTGAG',
            '3,PB1F_bc1003,ACACATCTCGTGAGAG',
            '4,PB1F_bc1004,CACGCACACACGCGCG',
            '5,PB1F_bc1005,CACGCACACACGCGCG'
          ].join("\n")
        )
        file.rewind
        file
      end
      let(:reverse_file) do
        reverse = Tempfile.new('reverse')
        reverse.write(
          [
            'Reverse Index Number,Reverse Oligo Label,R index sequence',
            '1,PB1R_bc1097_rc,TAGAGAGATAGAGACG',
            '2,PB1R_bc1098_rc,TGATGTGACACTGCGC',
            '3,PB1R_bc1099_rc,AGTACAGTGTAGTAGA',
            '4,PB1R_bc1100_rc,ACTACTGAGACATAGA',
            '5,PB1R_bc1101_rc,TATATCGCGTCGCTAT',
            '6,PB1R_bc1102_rc,CTATCATATCGAGAGA',
            '7,PB1R_bc1103_rc,CGAGCGAGTGTGTATA',
            '8,PB1R_bc1104_rc,CACGAGTCACTCATAT'
          ].join("\n")
        )
        reverse.rewind
        reverse
      end
      let(:run_task) { described_class.process_create_tag_groups(forward_file, reverse_file.path, 'v1') }

      it 'creates the tag group with the right indexing' do
        run_task
        %w[Bioscan_reverse_4_1_v1 Bioscan_reverse_4_2_v1].each do |name|
          indexes = TagGroup.find_by(name: name).tags.map(&:map_id)
          expect(indexes).to eq([1, 2, 3, 4])
        end

        indexes = TagGroup.find_by(name: 'Bioscan_forward_96_v1').tags.map(&:map_id)
        expect(indexes).to eq([1, 2, 3, 4, 5])
      end

      it 'creates the expected tag layout templates' do
        run_task
        expect(TagLayoutTemplate.all.map(&:name)).to eq(%w[Bioscan_384_template_1_v1 Bioscan_384_template_2_v1])
      end

      it 'creates the right content in the yaml file' do
        run_task

        contents = YAML.safe_load_file('mbrave.yml', aliases: true)
        expect(contents[Rails.env].keys).to eq(%w[Bioscan_forward_96_v1 Bioscan_reverse_4_1_v1 Bioscan_reverse_4_2_v1])

        expect(contents[Rails.env]['Bioscan_forward_96_v1']['num_plate']).to eq(1)
        expect(contents[Rails.env]['Bioscan_reverse_4_1_v1']['num_plate']).to eq(1)
        expect(contents[Rails.env]['Bioscan_reverse_4_2_v1']['num_plate']).to eq(2)

        expect(contents[Rails.env]['Bioscan_forward_96_v1']['version']).to eq('v1')
        expect(contents[Rails.env]['Bioscan_reverse_4_1_v1']['version']).to eq('v1')
        expect(contents[Rails.env]['Bioscan_reverse_4_2_v1']['version']).to eq('v1')

        expect(contents[Rails.env]['Bioscan_forward_96_v1']['tags']).to eq(
          %w[PB1F_bc1001 PB1F_bc1002 PB1F_bc1003 PB1F_bc1004 PB1F_bc1005]
        )

        expect(contents[Rails.env]['Bioscan_reverse_4_1_v1']['tags']).to eq(
          %w[PB1R_bc1097_rc PB1R_bc1098_rc PB1R_bc1099_rc PB1R_bc1100_rc]
        )

        expect(contents[Rails.env]['Bioscan_reverse_4_2_v1']['tags']).to eq(
          %w[PB1R_bc1101_rc PB1R_bc1102_rc PB1R_bc1103_rc PB1R_bc1104_rc]
        )
      end
    end
  end
end
