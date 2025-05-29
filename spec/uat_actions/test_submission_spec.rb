# frozen_string_literal: true

require 'rails_helper'

describe UatActions::TestSubmission do
  context 'valid options' do
    before { expect(PlateBarcode).to receive(:create_barcode).and_return(first_plate_barcode) }

    let(:submission_template) { create(:limber_wgs_submission_template) }
    let(:primer_panel) { create(:primer_panel) }
    let(:parameters) { { submission_template_name: submission_template.name } }
    let(:uat_action) { described_class.new(parameters) }
    let(:first_plate_barcode) { build(:plate_barcode) }
    let(:report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      { 'plate_barcode_0' => first_plate_barcode[:barcode] }
    end

    it 'can be performed' do
      expect(uat_action.perform).to be true
      expect(uat_action.report['plate_barcode_0']).to eq report['plate_barcode_0']
      expect(uat_action.report['submission_id']).to be_a Integer
      expect(uat_action.report['study_name']).to be_present
      expect(uat_action.report['project_name']).to be_present
    end

    context 'with optional plate purpose supplied' do
      let(:parameters) do
        {
          submission_template_name: submission_template.name,
          plate_purpose_name: PlatePurpose.stock_plate_purpose.name
        }
      end

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['plate_barcode_0']).to eq report['plate_barcode_0']
        expect(uat_action.report['submission_id']).to be_a Integer
      end
    end

    context 'with optional library type supplied' do
      let(:parameters) { { submission_template_name: submission_template.name, library_type_name: 'Standard' } }

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['plate_barcode_0']).to eq report['plate_barcode_0']
        expect(uat_action.report['submission_id']).to be_a Integer
        expect(uat_action.report['library_type']).to eq 'Standard'
      end
    end

    context 'with optional primer panel supplied' do
      let(:parameters) do
        {
          submission_template_name: submission_template.name,
          library_type_name: 'Standard',
          primer_panel_name: 'Primer Panel 1'
        }
      end

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['plate_barcode_0']).to eq report['plate_barcode_0']
        expect(uat_action.report['submission_id']).to be_a Integer
        expect(uat_action.report['library_type']).to eq 'Standard'
        expect(uat_action.report['primer_panel']).to eq 'Primer Panel 1'
      end
    end

    context 'with optional number of wells with samples supplied' do
      let(:parameters) { { submission_template_name: submission_template.name, number_of_wells_with_samples: '2' } }

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['plate_barcode_0']).to eq report['plate_barcode_0']
        expect(uat_action.report['submission_id']).to be_a Integer
        expect(uat_action.report['number_of_wells_with_samples']).to be_a Integer
      end
    end

    context 'with optional number of wells to submit supplied' do
      let(:parameters) { { submission_template_name: submission_template.name, number_of_wells_to_submit: '2' } }

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['plate_barcode_0']).to eq report['plate_barcode_0']
        expect(uat_action.report['number_of_wells_to_submit']).to be_a Integer
      end
    end

    context 'with optional number of samples per well supplied' do
      let(:parameters) { { submission_template_name: submission_template.name, number_of_samples_in_each_well: '2' } }

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['plate_barcode_0']).to eq report['plate_barcode_0']
        expect(uat_action.report['number_of_samples_in_each_well']).to be_a Integer
      end
    end

    context 'with optional study name supplied' do
      let(:study_name) { 'Test Study' }
      let(:study) { create(:study, name: study_name) }
      let(:parameters) { { submission_template_name: submission_template.name, study_name: study_name } }

      before { allow(Study).to receive(:find_by!).with(name: study_name).and_return(study) }

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['plate_barcode_0']).to eq report['plate_barcode_0']
        expect(uat_action.report['study_name']).to eq study_name
      end
    end

    context 'with optional project name supplied' do
      let(:project_name) { 'Test Project' }
      let(:project) { create(:project, name: project_name) }
      let(:parameters) { { submission_template_name: submission_template.name, project_name: project_name } }

      before { allow(Project).to receive(:find_by).with(name: project_name).and_return(project) }

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['plate_barcode_0']).to eq report['plate_barcode_0']
        expect(uat_action.report['project_name']).to eq project_name
      end
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end

  describe '#valid?' do
    let(:uat_action) { described_class.new(parameters) }

    describe '#validate_submission_template_exists' do
      let(:parameters) { { submission_template_name: } }
      let(:error_message) do
        format(described_class::ERROR_SUBMISSION_TEMPLATE_DOES_NOT_EXIST, submission_template_name)
      end

      context 'when the submission template does not exist' do
        let(:submission_template_name) { 'Invalid Submission Template' }

        it 'adds the error message' do
          expect(uat_action.valid?).to be false
          expect(uat_action.errors[:submission_template_name]).to include(error_message)
        end
      end

      context 'when the submission template exists' do
        let(:submission_template) { create(:submission_template) }
        let(:submission_template_name) { submission_template.name }

        it 'does not add the error message' do
          uat_action.valid? # run validations
          expect(uat_action.errors[:submission_template_name]).not_to include(error_message)
        end
      end
    end

    describe '#validate_plate_exists' do
      let(:parameters) { { plate_barcode: } }
      let(:error_message) { format(described_class::ERROR_PLATE_DOES_NOT_EXIST, plate_barcode) }

      context 'when the plate does not exist' do
        let(:plate_barcode) { 'Invalid Plate Barcode' }

        it 'adds the error message' do
          expect(uat_action.valid?).to be false
          expect(uat_action.errors[:plate_barcode]).to include(error_message)
        end
      end

      context 'when the plate purpose exists' do
        let(:plate) { create(:plate) }
        let(:plate_barcode) { plate.human_barcode }

        it 'does not add the error message' do
          uat_action.valid? # run validations
          expect(uat_action.errors[:plate_barcode]).not_to include(error_message)
        end
      end
    end

    describe '#validate_plate_purpose_exists' do
      let(:parameters) { { plate_purpose_name: } }
      let(:error_message) { format(described_class::ERROR_PLATE_PURPOSE_DOES_NOT_EXIST, plate_purpose_name) }

      context 'when the plate purpose does not exist' do
        let(:plate_purpose_name) { 'Invalid Plate Purpose' }

        it 'adds the error message' do
          expect(uat_action.valid?).to be false
          expect(uat_action.errors[:plate_purpose_name]).to include(error_message)
        end
      end

      context 'when the plate purpose exists' do
        let(:plate) { create(:plate) }
        let(:plate_purpose_name) { plate.purpose.name }

        it 'does not add the error message' do
          uat_action.valid? # run validations
          expect(uat_action.errors[:plate_purpose_name]).not_to include(error_message)
        end
      end
    end

    describe '#validate_library_type_exists' do
      let(:parameters) { { library_type_name: } }
      let(:error_message) { format(described_class::ERROR_LIBRARY_TYPE_DOES_NOT_EXIST, library_type_name) }

      context 'when the library type does not exist' do
        let(:library_type_name) { 'Invalid Library Type' }

        it 'adds the error message' do
          expect(uat_action.valid?).to be false
          expect(uat_action.errors[:library_type_name]).to include(error_message)
        end
      end

      context 'when the library type exists' do
        let(:library_type) { create(:library_type) }
        let(:library_type_name) { library_type.name }

        it 'does not add the error message' do
          uat_action.valid? # run validations
          expect(uat_action.errors[:library_type_name]).not_to include(error_message)
        end
      end
    end

    describe '#validate_primer_panel_exists' do
      let(:parameters) { { primer_panel_name: } }
      let(:error_message) { format(described_class::ERROR_PRIMER_PANEL_DOES_NOT_EXIST, primer_panel_name) }

      context 'when the primer panel does not exist' do
        let(:primer_panel_name) { 'Invalid Primer Panel' }

        it 'adds the error message' do
          expect(uat_action.valid?).to be false
          expect(uat_action.errors[:primer_panel_name]).to include(error_message)
        end
      end

      context 'when the primer panel exists' do
        let(:primer_panel) { create(:primer_panel) }
        let(:primer_panel_name) { primer_panel.name }

        it 'does not add the error message' do
          uat_action.valid? # run validations
          expect(uat_action.errors[:primer_panel_name]).not_to include(error_message)
        end
      end
    end
  end

  describe '#project' do
    subject(:test_submission) { described_class.new(parameters) }

    context 'when project_name is provided' do
      let(:project_name) { 'Custom Project' }
      let(:project) { create(:project, name: project_name) }
      let(:parameters) { { project_name: } }

      before { allow(Project).to receive(:find_by).with(name: project_name).and_return(project) }

      it 'returns the project with the matching name' do
        expect(test_submission.send(:project)).to eq(project)
      end
    end

    context 'when project_name is not provided' do
      let(:parameters) { {} }
      let(:static_project) { create(:project, name: 'UAT Project') }

      before { allow(UatActions::StaticRecords).to receive(:project).and_return(static_project) }

      it 'returns the default static project' do
        expect(test_submission.send(:project)).to eq(static_project)
      end
    end
  end

  describe '#setup_generator' do
    subject(:test_submission) { described_class.new(parameters) }

    let(:generator) { instance_double(UatActions::GeneratePlates) }
    let(:default_purpose_name) { 'Default Purpose' }

    before do
      allow(UatActions::GeneratePlates).to receive(:default).and_return(generator)
      allow(generator).to receive(:plate_purpose_name=)
      allow(generator).to receive(:well_count=)
      allow(generator).to receive(:well_layout=)
      allow(generator).to receive(:number_of_samples_in_each_well=)
      allow(generator).to receive(:study_name=)
      # rubocop:disable RSpec/SubjectStub
      allow(test_submission).to receive(:default_purpose_name).and_return(default_purpose_name)
      # rubocop:enable RSpec/SubjectStub
    end

    context 'with default parameters' do
      let(:parameters) { {} }

      it 'configures the generator with the default purpose name' do
        test_submission.send(:setup_generator)
        expect(generator).to have_received(:plate_purpose_name=).with(default_purpose_name)
      end

      it 'configures the generator with the default well count' do
        test_submission.send(:setup_generator)
        expect(generator).to have_received(:well_count=).with(96)
      end

      it 'configures the generator with Random layout' do
        test_submission.send(:setup_generator)
        expect(generator).to have_received(:well_layout=).with('Random')
      end

      it 'configures the generator with one sample per well' do
        test_submission.send(:setup_generator)
        expect(generator).to have_received(:number_of_samples_in_each_well=).with(1)
      end

      it 'does not set a study name' do
        test_submission.send(:setup_generator)
        expect(generator).not_to have_received(:study_name=)
      end
    end

    context 'with custom parameters' do
      let(:parameters) do
        {
          plate_purpose_name: 'Custom Purpose',
          number_of_wells_with_samples: '48',
          number_of_samples_in_each_well: '3',
          study_name: 'Test Study'
        }
      end

      it 'configures the generator with the custom purpose name' do
        test_submission.send(:setup_generator)
        expect(generator).to have_received(:plate_purpose_name=).with('Custom Purpose')
      end

      it 'configures the generator with the custom well count' do
        test_submission.send(:setup_generator)
        expect(generator).to have_received(:well_count=).with(48)
      end

      it 'configures the generator with Random layout' do
        test_submission.send(:setup_generator)
        expect(generator).to have_received(:well_layout=).with('Random')
      end

      it 'configures the generator with multiple samples per well' do
        test_submission.send(:setup_generator)
        expect(generator).to have_received(:number_of_samples_in_each_well=).with(3)
      end

      it 'configures the generator with the specified study name' do
        test_submission.send(:setup_generator)
        expect(generator).to have_received(:study_name=).with('Test Study')
      end
    end
  end

  describe 'form field select_options' do
    describe '.compatible_submission_templates' do
      let(:well_request_type) { create(:request_type, asset_type: 'Well') }
      let(:tube_request_type) { create(:request_type, asset_type: 'Tube') }

      before do
        # Create submission templates with the request type properly associated
        # For well template (visible)
        create(
          :submission_template,
          name: 'Template A',
          submission_parameters: {
            request_type_ids_list: [[well_request_type.id]]
          },
          # visible is a scope, not an attribute - use superceded_by_id instead
          superceded_by_id: SubmissionTemplate::LATEST_VERSION
        )

        # For tube template (visible)
        create(
          :submission_template,
          name: 'Template B',
          submission_parameters: {
            request_type_ids_list: [[tube_request_type.id]]
          },
          superceded_by_id: SubmissionTemplate::LATEST_VERSION
        )

        # For hidden well template
        create(
          :submission_template,
          name: 'Template C',
          submission_parameters: {
            request_type_ids_list: [[well_request_type.id]]
          },
          # Any value other than LATEST_VERSION will make it hidden
          superceded_by_id: 123
        )
      end

      it 'returns templates with Well input asset type' do
        templates = described_class.compatible_submission_templates

        expect(templates).to include('Template A')
        expect(templates).not_to include('Template B') # Wrong asset type
        expect(templates).not_to include('Template C') # Not visible
      end
    end

    describe 'primer panel, study, and project options' do
      before do
        # Create primer panels in non-alphabetical order
        create(:primer_panel, name: 'C Primer Panel')
        create(:primer_panel, name: 'A Primer Panel')
        create(:primer_panel, name: 'B Primer Panel')

        # Create studies in non-alphabetical order with different states
        create(:study, name: 'Z Inactive Study', state: 'inactive')
        create(:study, name: 'C Active Study', state: 'active')
        create(:study, name: 'A Active Study', state: 'active')
        create(:study, name: 'B Active Study', state: 'active')

        # Create projects in non-alphabetical order with different statuses
        create(:project, name: 'Z Archived Project', state: 'inactive')
        create(:project, name: 'C Active Project', state: 'active')
        create(:project, name: 'A Active Project', state: 'active')
        create(:project, name: 'B Active Project', state: 'active')
      end

      it 'returns records alphabetically' do
        # We can't access form_fields directly, so we're just testing
        # the underlying methods that would be used by the select_options Procs
        expect(PrimerPanel.alphabetical.pluck(:name)).to eq(['A Primer Panel', 'B Primer Panel', 'C Primer Panel'])
        expect(Study.active.alphabetical.pluck(:name)).to eq(['A Active Study', 'B Active Study', 'C Active Study'])
        expect(Project.active.alphabetical.pluck(:name)).to eq(
          ['A Active Project', 'B Active Project', 'C Active Project']
        )
      end
    end
  end
end
