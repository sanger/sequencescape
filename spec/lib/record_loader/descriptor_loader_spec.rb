# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/descriptor_loader'

# This file was initially generated via `rails g record_loader`
RSpec.describe RecordLoader::DescriptorLoader, :loader, type: :model do
  def a_new_record_loader
    described_class.new(directory: test_directory, files: selected_files)
  end

  subject(:record_loader) { a_new_record_loader }

  # Tests use a separate directory to avoid coupling your specs to the data
  let(:test_directory) { Rails.root.join('spec/data/record_loader/descriptors') }

  context 'with descriptors_basic selected' do
    let(:selected_files) { 'descriptors_basic' }
    let!(:workflow) { create(:workflow, name: 'workflow 1') }
    let!(:task) { create(:task, name: 'task 1', pipeline_workflow_id: workflow.id) }

    it 'creates two records' do
      expect { record_loader.create! }.to change(Descriptor, :count).by(2)
    end

    # It is important that multiple runs of a RecordLoader do not create additional
    # copies of existing records.
    it 'is idempotent' do
      record_loader.create!
      expect { a_new_record_loader }.not_to change(Descriptor, :count)
    end

    it 'sets attributes on the created records' do
      record_loader.create!
      expect(Descriptor.all).to include(
        have_attributes(
          name: 'name 1',
          value: 'value 1',
          selection: 'selection 1',
          kind: 'kind 1',
          required: false,
          sorter: 1,
          key: 'key 1',
          task_id: task.id
        ),
        have_attributes(
          name: 'name 2',
          value: 'value 2',
          selection: 'selection 2',
          kind: 'kind 2',
          required: false,
          sorter: 2,
          key: 'key 2',
          task_id: task.id
        )
      )
    end
  end
end
