# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/submission_template_loader'

# This file was initially generated via `rails g record_loader`
RSpec.describe RecordLoader::SubmissionTemplateLoader, :loader, type: :model do
  subject(:record_loader) { described_class.new(directory: test_directory, files: selected_files) }

  # Tests use a separate directory to avoid coupling your specs to the data
  let(:test_directory) { Rails.root.join('spec/data/record_loader/submission_templates') }

  context 'with two_submission_templates selected' do
    let(:selected_files) { 'two_submission_templates' }
    let!(:project) { UatActions::StaticRecords.project }
    let!(:product_line) { ProductLine.create!(name: 'my_product_line') }
    let!(:product_cat) { ProductCatalogue.create!(name: 'my_product_cat') }
    let!(:request_type) { create(:request_type, key: 'my_request_type') }
    let!(:request_type2) { create(:request_type, key: 'my_request_type2') }
    let!(:order_role) { OrderRole.create!(role: 'my_order_role') }

    it 'creates two records' do
      expect { record_loader.create! }.to change(SubmissionTemplate, :count).by(2)
    end

    # It is important that multiple runs of a RecordLoader do not create additional
    # copies of existing records.
    it 'is idempotent' do
      record_loader.create!
      expect { record_loader.create! }.not_to change(SubmissionTemplate, :count)
    end

    it 'sets attributes on the created records' do
      record_loader.create!

      rec1 = SubmissionTemplate.find_by(name: 'test_submission_template_1')
      rec2 = SubmissionTemplate.find_by(name: 'test_submission_template_2')

      expect(rec1).to have_attributes(
        submission_class_name: 'LinearSubmission',
        submission_parameters: {
          request_type_ids_list: [request_type.id, request_type2.id],
          order_role_id: order_role.id,
          project_id: project.id
        },
        product_line_id: product_line.id,
        product_catalogue_id: product_cat.id
      )

      expect(rec2).to have_attributes(
        submission_class_name: 'LinearSubmission',
        submission_parameters: {
          request_type_ids_list: [request_type.id, request_type2.id],
          project_id: project.id
        },
        product_line_id: product_line.id,
        product_catalogue_id: product_cat.id
      )
    end
  end
end
