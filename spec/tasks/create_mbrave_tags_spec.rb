# frozen_string_literal: true
require 'spec_helper'
require 'rake'

# rubocop:todo RSpec/DescribeClass
describe 'mbrave tasks' do
  # rubocop:disable RSpec/BeforeAfterAll
  before(:all) do
    # Ensure Rake is properly initialised before all tests
    Rake.application = Rake::Application.new
    Rails.application.load_tasks
  end
  # rubocop:enable RSpec/BeforeAfterAll

  describe 'mbrave:create_tag_plates' do
    before { Rake::Task['mbrave:create_tag_plates'].reenable }

    describe 'when invoked without arguments' do
      it 'does not do anything' do
        expect(MbraveTagsCreator).not_to receive(:process_create_tag_plates)
        Rake::Task['mbrave:create_tag_plates'].execute
      end
    end

    describe 'when invoked with arguments' do
      let(:login) { 'test' }
      let(:version) { 'v1' }

      it 'creates tag plates' do
        expect(MbraveTagsCreator).to receive(:process_create_tag_plates).with(login, version).at_least(:once)
        Rake::Task['mbrave:create_tag_plates'].execute(login:, version:)
      end
    end
  end

  describe 'mbrave:create_tag_groups' do
    before { Rake::Task['mbrave:create_tag_groups'].reenable }

    describe 'when invoked without arguments' do
      it 'does not write the file' do
        expect(MbraveTagsCreator).not_to receive(:process_create_tag_groups)
        Rake.application.invoke_task 'mbrave:create_tag_groups'
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
        Rake::Task['mbrave:create_tag_groups'].execute(forward_file:, reverse_file:, version:)
      end
      # rubocop:enable RSpec/ExampleLength
    end
  end
end
# rubocop:enable RSpec/DescribeClass
