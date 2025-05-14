# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/task_loader'

# This file was initially generated via `rails g record_loader`
RSpec.describe RecordLoader::TaskLoader, :loader, type: :model do
  def a_new_record_loader
    described_class.new(directory: test_directory, files: selected_files)
  end

  subject(:record_loader) { a_new_record_loader }

  # Tests use a separate directory to avoid coupling your specs to the data
  let(:test_directory) { Rails.root.join('spec/data/record_loader/tasks') }

  context 'with tasks_basic selected' do
    let(:selected_files) { 'tasks_basic' }
    let!(:workflow) { create(:workflow, name: 'workflow 1') }

    it 'creates two records' do
      expect { record_loader.create! }.to change(Task, :count).by(2)
    end

    # It is important that multiple runs of a RecordLoader do not create additional
    # copies of existing records.
    it 'is idempotent' do
      record_loader.create!
      expect { a_new_record_loader }.not_to change(Task, :count)
    end

    it 'sets attributes on the created records' do
      record_loader.create!
      expect(Task.all).to include(
        have_attributes(
          name: 'name 1',
          pipeline_workflow_id: workflow.id,
          sorted: 1,
          batched: false,
          location: 'location 1',
          interactive: false,
          per_item: false,
          lab_activity: false
        ),
        have_attributes(
          name: 'name 2',
          pipeline_workflow_id: workflow.id,
          sorted: 2,
          batched: false,
          location: 'location 2',
          interactive: false,
          per_item: false,
          lab_activity: false
        )
      )
    end
  end
end
