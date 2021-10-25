# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/submission_template_loader'

# This file was initially generated via `rails g record_loader`
RSpec.describe RecordLoader::SubmissionTemplateLoader, type: :model, loader: true do
  subject(:record_loader) { described_class.new(directory: test_directory, files: selected_files) }

  # Tests use a separate directory to avoid coupling your specs to the data
  let(:test_directory) { Rails.root.join('spec/data/record_loader/submission_templates') }

  context 'with two_entry_example selected' do
    let(:selected_files) { 'two_entry_example' }

    it 'creates two records' do
      expect { record_loader.create! }.to change(SubmissionTemplate, :count).by(2)
    end

    # It is important that multiple runs of a RecordLoader do not create additional
    # copies of existing records.
    it 'is idempotent' do
      record_loader.create!
      expect { record_loader.create! }.not_to change(SubmissionTemplate, :count)
    end

    it 'sets attributes on the created records'
  end
end
