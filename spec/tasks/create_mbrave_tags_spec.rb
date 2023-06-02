# frozen_string_literal: true
require 'spec_helper'
require 'rake'

# rubocop:todo RSpec/DescribeClass
describe 'mbrave tasks' do
  let(:queue_mode_setup) do
    if ENV.key?('KNAPSACK_PRO_FIXED_QUEUE_SPLIT')
      %w[mbrave:create_tag_plates mbrave:create_tag_groups].each do |task_name|
        Rake::Task[task_name].clear if Rake::Task.task_defined?(task_name)
      end
    end
  end

  describe 'mbrave:create_tag_plates' do
    before do
      queue_mode_setup

      Rake.application.rake_require 'tasks/create_mbrave_tags'
      Rake::Task.define_task(:environment)
    end

    context 'with mbrave:create_tag_plates' do
      context 'when the create_tag_plates task is invoked' do
        context 'when there are no arguments' do
          it 'does not do anything' do
            Rake::Task['mbrave:create_tag_plates'].reenable
            expect { Rake::Task['mbrave:create_tag_plates'].execute }.not_to change(Plate, :count)
          end
        end

        context 'when receiving the right arguments' do
          let(:tag_group_one) { create(:tag_group) }
          let(:tag_purpose) { create(:plate_purpose, name: 'Tag Plate') }
          let(:run_action) do
            Rake::Task['mbrave:create_tag_plates'].reenable
            Rake::Task['mbrave:create_tag_plates'].execute(login: 'test', version: 'v1') 
          end
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

            allow(PlateBarcode).to receive(:create_barcode).and_return(build(:plate_barcode))
          end

          it 'creates tag plates' do
            expect { run_action }.to change(Plate, :count).by(3)
          end
        end
      end
    end
  end

  describe 'mbrave:create_tag_groups' do
    before do
      queue_mode_setup

      Rake.application.rake_require 'tasks/create_mbrave_tags'
      Rake::Task.define_task(:environment)
    end

    context 'when the create_mbrave_tags task is invoked' do
      context 'when there are no arguments' do
        it 'does not write the file' do
          expect(File).not_to receive(:write)

          Rake::Task['mbrave:create_tag_groups'].reenable
          Rake.application.invoke_task 'mbrave:create_tag_groups'
        end
      end

      context 'when there is valid arguments' do
        let(:forward_file) do
          file = Tempfile.new('forward')
          file.write(
            [
              'Forward Index Number,Forward Oligo Label,F index sequence',
              '1,PB1F_bc1001,CACATATCAGAGTGCG',
              '2,PB1F_bc1002,ACACACAGACTGTGAG',
              '3,PB1F_bc1003,ACACATCTCGTGAGAG',
              '4,PB1F_bc1004,CACGCACACACGCGCG'
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
        let(:run_task) do
          Rake::Task['mbrave:create_tag_groups'].reenable
          Rake::Task['mbrave:create_tag_groups'].execute(
            forward_file: forward_file.path,
            reverse_file: reverse_file.path,
            version: 'v1'
          )
        end

        it 'creates the expected tag layout templates' do
          run_task
          expect(TagLayoutTemplate.all.map(&:name)).to eq(%w[Bioscan_384_template_1_v1 Bioscan_384_template_2_v1])
        end

        it 'creates the right content in the yaml file' do
          run_task

          contents = YAML.safe_load(File.read('mbrave.yml'), aliases: true)
          expect(contents[Rails.env].keys).to eq(
            %w[Bioscan_forward_96_v1 Bioscan_reverse_4_1_v1 Bioscan_reverse_4_2_v1]
          )

          expect(contents[Rails.env]['Bioscan_forward_96_v1']['num_plate']).to eq(1)
          expect(contents[Rails.env]['Bioscan_reverse_4_1_v1']['num_plate']).to eq(1)
          expect(contents[Rails.env]['Bioscan_reverse_4_2_v1']['num_plate']).to eq(2)

          expect(contents[Rails.env]['Bioscan_forward_96_v1']['version']).to eq('v1')
          expect(contents[Rails.env]['Bioscan_reverse_4_1_v1']['version']).to eq('v1')
          expect(contents[Rails.env]['Bioscan_reverse_4_2_v1']['version']).to eq('v1')

          expect(contents[Rails.env]['Bioscan_forward_96_v1']['tags']).to eq(
            %w[PB1F_bc1001 PB1F_bc1002 PB1F_bc1003 PB1F_bc1004]
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
end
# rubocop:enable RSpec/DescribeClass
