# frozen_string_literal: true

require 'rails_helper'

describe 'support:add_stock_rna_plate_to_working_dilution_parents', type: :task do
  let(:source_purpose_name) { 'Stock RNA Plate' }
  let(:target_purpose_name) { 'Working Dilution' }
  let(:plate_creator_name) { 'Working dilution' }

  let(:source_purpose) { create(:plate_purpose, name: source_purpose_name, stock_plate: true) }
  let(:target_purpose) { create(:plate_purpose, name: target_purpose_name, stock_plate: false) }
  let(:plate_creator) { create(:plate_creator, name: plate_creator_name) }

  let(:task) { Rake::Task[self.class.top_level_description] }

  # rubocop:disable RSpec/BeforeAfterAll
  before(:all) do
    Rake.application.rake_require('tasks/support/add_stock_rna_plate_to_working_dilution_parents')
    Rake::Task.define_task(:environment)
  end
  # rubocop:enable RSpec/BeforeAfterAll

  before do
    task.reenable
    plate_creator # The task assumes the plate creator already exists
    target_purpose # The task assumes the target purpose already exists
  end

  context 'when the source purpose is not in parent purposes' do
    before { source_purpose }

    it 'adds the source purpose' do
      expect(plate_creator.parent_plate_purposes).not_to include(source_purpose)
      task.invoke
      plate_creator.reload # Reload to get the updated parent purposes
      expect(plate_creator.parent_plate_purposes).to include(source_purpose)
      expect(plate_creator.parent_plate_purposes.where(name: source_purpose_name).count).to eq(1)
    end
  end

  context 'when the source purpose is already in parent purposes' do
    before do
      source_purpose
      plate_creator.parent_plate_purposes << source_purpose
    end

    it 'does not add the source purpose' do
      expect(plate_creator.parent_plate_purposes).to include(source_purpose)
      task.invoke
      plate_creator.reload # Reload to get the updated parent purposes
      expect(plate_creator.parent_plate_purposes).to include(source_purpose)
      expect(plate_creator.parent_plate_purposes.where(name: source_purpose_name).count).to eq(1)
    end
  end

  context 'when the source purpose does not exist' do
    it 'creates the source purpose' do
      expect(PlatePurpose.find_by(name: source_purpose_name)).to be_nil
      task.invoke
      expect(PlatePurpose.last.name).to eq(source_purpose_name)
      expect(PlatePurpose.where(name: source_purpose_name).count).to eq(1)
    end
  end

  context 'when the source purpose already exists' do
    before { source_purpose }

    it 'does not create the source purpose' do
      expect(PlatePurpose.find_by(name: source_purpose_name)).not_to be_nil
      task.invoke
      expect(PlatePurpose.last.name).to eq(source_purpose_name)
      expect(PlatePurpose.where(name: source_purpose_name).count).to eq(1)
    end
  end
end
