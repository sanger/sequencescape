# frozen_string_literal: true
require 'spec_helper'
require 'rake'

# rubocop:todo RSpec/DescribeClass
describe 'mbrave tasks' do
  let(:task) { Rake::Task[task_name] }

  before do
    Rake::Task[task_name].clear if Rake::Task.task_defined?(task_name)
    Rake::Task[:environment].clear if Rake::Task.task_defined?(:environment)
    Rake.load_rakefile('tasks/create_mbrave_tags.rake')
    Rake::Task.define_task(:environment)
    Rake::Task[task_name].reenable
  end

  describe 'mbrave:create_tag_plates' do
    let(:task_name) { 'mbrave:create_tag_plates' }

    describe 'when invoked without arguments' do
      it 'does not do anything' do
        expect(MbraveTagsCreator).not_to receive(:process_create_tag_plates)
        task.execute
      end
    end

    describe 'when invoked with arguments' do
      let(:login) { 'test' }
      let(:version) { 'v1' }

      it 'creates tag plates' do
        expect(MbraveTagsCreator).to receive(:process_create_tag_plates).with(login, version).at_least(:once)
        task.execute(login:, version:)
      end
    end
  end

  describe 'mbrave:create_tag_groups' do
    let(:task_name) { 'mbrave:create_tag_groups' }

    describe 'when invoked without arguments' do
      it 'does not write the file' do
        expect(MbraveTagsCreator).not_to receive(:process_create_tag_groups)
        task.invoke
      end
    end

    describe 'when invoked with arguments' do
      let(:forward_file) { 'forward' }
      let(:reverse_file) { 'reverse' }
      let(:version) { 'v1' }

      # rubocop:disable RSpec/ExampleLength
      it 'creates the tag group with the right indexing' do
        expect(MbraveTagsCreator).to receive(:process_create_tag_groups).with(
          forward_file,
          reverse_file,
          version
        ).at_least(:once)
        task.execute(forward_file:, reverse_file:, version:)
      end
      # rubocop:enable RSpec/ExampleLength
    end
  end
end
# rubocop:enable RSpec/DescribeClass
