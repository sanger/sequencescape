# frozen_string_literal: true
require 'spec_helper'
require 'rake'

# rubocop:todo RSpec/DescribeClass
describe 'mbrave tasks' do
  after { Rake.application.clear }

  before { Rails.application.load_tasks }

  describe 'mbrave:create_tag_plates' do
    before { Rake::Task['mbrave:create_tag_plates'].reenable }

    context 'with mbrave:create_tag_plates' do
      context 'when the create_tag_plates task is invoked' do
        context 'when there are no arguments' do
          it 'does not do anything' do
            expect(MbraveTagsCreator).not_to receive(:process_create_tag_plates)
            Rake::Task['mbrave:create_tag_plates'].execute
          end
        end

        context 'when receiving the right arguments' do
          let(:run_action) { Rake::Task['mbrave:create_tag_plates'].execute(login: 'test', version: 'v1') }

          it 'creates tag plates' do
            expect(MbraveTagsCreator).to receive(:process_create_tag_plates).with('test', 'v1').at_least(:once)
            run_action
          end
        end
      end
    end
  end

  describe 'mbrave:create_tag_groups' do
    before { Rake::Task['mbrave:create_tag_groups'].reenable }

    context 'when the create_mbrave_tags task is invoked' do
      context 'when there are no arguments' do
        it 'does not write the file' do
          expect(MbraveTagsCreator).not_to receive(:process_create_tag_groups)
          Rake.application.invoke_task 'mbrave:create_tag_groups'
        end
      end

      context 'when there is valid arguments' do
        let(:run_task) do
          Rake::Task['mbrave:create_tag_groups'].execute(
            forward_file: 'forward',
            reverse_file: 'reverse',
            version: 'v1'
          )
        end

        it 'creates the tag group with the right indexing' do
          expect(MbraveTagsCreator).to
          receive(:process_create_tag_groups).with('forward', 'reverse', 'v1').at_least(:once)
          run_task
        end
      end
    end
  end
end
# rubocop:enable RSpec/DescribeClass
