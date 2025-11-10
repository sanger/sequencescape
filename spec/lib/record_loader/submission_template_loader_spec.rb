# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/submission_template_loader'

# This file was initially generated via `rails g record_loader`
RSpec.describe RecordLoader::SubmissionTemplateLoader, :loader, type: :model do
  subject(:record_loader) { described_class.new(directory: test_directory, files: selected_files) }

  # Tests use a separate directory to avoid coupling your specs to the data
  let(:test_directory) { Rails.root.join('spec/data/record_loader/submission_templates') }
  let(:selected_files) { 'two_submission_templates' }

  let!(:study) { UatActions::StaticRecords.study }
  let!(:project) { UatActions::StaticRecords.project }

  let(:role) { 'my_order_role' }
  let!(:order_role) { OrderRole.create!(role:) }

  context 'with two_submission_templates selected' do
    let!(:product_line) { ProductLine.create!(name: 'my_product_line') }
    let!(:product_cat) { ProductCatalogue.create!(name: 'my_product_cat') }
    let!(:request_type) { create(:request_type, key: 'my_request_type') }
    let!(:request_type2) { create(:request_type, key: 'my_request_type2') }

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

      rec1 = SubmissionTemplate.find_by!(name: 'test_submission_template_1')
      rec2 = SubmissionTemplate.find_by!(name: 'test_submission_template_2')

      # NB. the project name in the test file is 'my_project', which does not exist, so it defaults to the UAT project
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

  describe '#find_order_role' do
    context 'when in production environment' do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production')) }

      context 'when the role already exists' do
        it 'finds the order role by role' do
          allow(OrderRole).to receive(:find_or_create_by!).with(role:).and_return(order_role)
          expect(record_loader.find_order_role(role)).to eq(order_role)
        end
      end

      context 'when the role does not exist' do
        it 'creates the order role' do
          allow(OrderRole).to receive(:find_or_create_by!).with(role:).and_return(order_role)
          expect(record_loader.find_order_role(role)).to eq(order_role)
        end
      end
    end

    context 'when not in production environment' do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development')) }

      context 'when the role already exists' do
        it 'finds the order role by role' do
          allow(OrderRole).to receive(:find_or_create_by).with(role:).and_return(order_role)
          expect(record_loader.find_order_role(role)).to eq(order_role)
        end
      end

      context 'when the role does not exist' do
        it 'returns the UAT order role' do
          allow(OrderRole).to receive(:find_or_create_by).with(role:).and_return(nil)
          allow(UatActions::StaticRecords).to receive(:order_role).and_return(order_role)
          expect(record_loader.find_order_role(role)).to eq(order_role)
        end
      end
    end
  end

  describe '#find_project' do
    context 'when in production environment' do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production')) }

      it 'finds the project by name' do
        allow(Project).to receive(:find_by!).with(name: 'Test Project').and_return(project)
        expect(record_loader.find_project('Test Project')).to eq(project)
      end
    end

    context 'when not in production environment' do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development')) }

      it 'finds the project by name or returns the UAT project' do
        allow(Project).to receive(:find_by).with(name: 'Test Project').and_return(nil)
        allow(UatActions::StaticRecords).to receive(:project).and_return(project)
        expect(record_loader.find_project('Test Project')).to eq(project)
      end
    end
  end

  describe '#find_study' do
    context 'when in production environment' do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production')) }

      it 'finds the study by name' do
        allow(Study).to receive(:find_by!).with(name: 'Test Study').and_return(study)
        expect(record_loader.find_study('Test Study')).to eq(study)
      end
    end

    context 'when not in production environment' do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development')) }

      it 'finds the study by name or returns the UAT study' do
        allow(Study).to receive(:find_by).with(name: 'Test Study').and_return(nil)
        allow(UatActions::StaticRecords).to receive(:study).and_return(study)
        expect(record_loader.find_study('Test Study')).to eq(study)
      end
    end
  end
end
