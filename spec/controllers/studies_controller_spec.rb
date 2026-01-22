# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StudiesController do
  include MockAccession
  include AccessionV1ClientHelper

  let(:data_release_study_type) { create(:data_release_study_type, name: 'genomic sequencing') }
  let(:reference_genome) { create(:reference_genome) }
  let(:study) { create(:study) }
  let(:program) { create(:program) }
  let(:user) { create(:owner) }

  let(:params) do
    {
      'study' => {
        'name' => 'hello',
        'reference_genome_id' => reference_genome.id,
        'study_metadata_attributes' => {
          'faculty_sponsor_id' => create(:faculty_sponsor, name: 'Me'),
          'study_description' => 'some new study',
          'ebi_library_strategy' => 'WGS',
          'ebi_library_source' => 'GENOMIC',
          'ebi_library_selection' => 'PCR',
          'program_id' => program.id,
          'contains_human_dna' => 'No',
          'contaminated_human_dna' => 'No',
          'commercially_available' => 'No',
          'data_release_study_type_id' => data_release_study_type,
          'data_release_strategy' => 'open',
          'study_type_id' => StudyType.find_or_create_by(name: 'Not specified').id
        }
      }
    }
  end

  before { session[:user] = user.id }

  it_behaves_like 'it requires login'

  describe '#new' do
    before { get :new }

    it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
      expect(subject).to respond_with :success
      expect(subject).to render_template :new
    end
  end

  describe '#create' do
    before do
      @study_count = Study.count
      post :create, params:
    end

    context 'with valid options' do
      it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
        expect(subject).to set_flash.to('Your study has been created')
        expect(subject).to redirect_to('study path') { study_path(Study.last) }
      end

      it 'changes Study.count by 1' do
        expect(Study.count - @study_count).to eq(1)
      end
    end

    context 'with invalid options' do
      before do
        @initial_study_count = Study.count
        post :create, params: { 'study' => { 'name' => 'hello 2' } }
      end

      let(:params) { { 'study' => { 'name' => 'hello 2' } } }

      specify(:aggregate_failures) do
        expect(subject).to render_template :new
        expect(subject).to set_flash.now.to('Problems creating your new study')
      end

      it 'not change Study.count' do
        expect(Study.count).to eq(@initial_study_count)
      end
    end
  end

  describe '#grant_role' do
    let(:user) { create(:admin) }

    before do
      session[:user] = user.id
      post :grant_role, params: { role: { user: user.id, authorizable_type: 'manager' }, id: study.id }, xhr: true
    end

    it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
      expect(subject).to respond_with :ok
      expect(subject).to set_flash.now.to('Role added')
    end
  end

  describe '#accession' do
    let(:study_metadata) { create(:study_metadata) }
    let(:study) { create(:open_study, study_metadata: create(:study_metadata_for_accessioning)) }

    context 'when accessioning is enabled', :accessioning_enabled, :un_delay_jobs do
      before do
        allow_any_instance_of(RestClient::Resource).to receive(:post).and_return(successful_study_accession_response)

        get :accession, params: { id: study.id }
      end

      it 'does not raise an error' do
        expect { study.reload }.not_to raise_error
      end

      it 'retrieves an accession number' do
        expect(study.reload.ebi_accession_number).to be_present
      end

      it 'displays a success message' do
        expect(flash[:notice]).to eq('Accession number generated: EGA00002000345')
      end

      it 'does not display an warning message' do
        expect(flash[:warning]).to be_nil
      end

      it 'does not display an error message' do
        expect(flash[:error]).to be_nil
      end

      it 'redirects to the study page' do
        expect(response).to redirect_to(study_path(study.id))
      end
    end

    context 'when accessioning is disabled' do
      before do
        get :accession, params: { id: study.id }
      end

      it 'does not raise an error' do
        expect { study.reload }.not_to raise_error
      end

      it 'does not retrieve an accession number' do
        expect(study.reload.ebi_accession_number).to be_nil
      end

      it 'does not display an info message' do
        expect(flash[:info]).to be_nil
      end

      it 'does not display an notice message' do
        expect(flash[:notice]).to be_nil
      end

      it 'does not display an warning message' do
        expect(flash[:warning]).to be_nil
      end

      it 'displays an error message' do
        expect(flash[:error]).to eq('Accessioning is not enabled in this environment.')
      end

      it 'redirects to the study page' do
        expect(response).to redirect_to(edit_study_path(study.id))
      end
    end
  end

  describe '#accession_all_samples', :accessioning_enabled, :un_delay_jobs do
    let(:number_of_samples) { 5 }
    let(:samples) { create_list(:sample_for_accessioning_with_open_study, number_of_samples) }
    let(:study) { samples.first.studies.first }

    before do
      create(:user, api_key: configatron.accession_local_key) # create contact user
      allow(Rails.logger).to receive(:info).and_call_original
      allow(Accession::Submission).to receive(:client).and_return(
        stub_accession_client(:submit_and_fetch_accession_number, return_value: 'EGA00001000240')
      )

      post :accession_all_samples, params: { id: study.id }
    end

    context 'when the accessioning succeeds' do
      it 'redirects to the accession-statuses tab of the study page' do
        expect(subject).to redirect_to(study_path(study, anchor: 'accession-statuses'))
      end

      it 'does not set a flash error message' do
        expect(flash[:error]).to be_nil
      end

      it 'does not set a flash warning message' do
        expect(flash[:warning]).to be_nil
      end

      it 'sets a flash notice message' do
        expect(flash[:notice]).to eq('All of the samples in this study have been sent for accessioning.')
      end

      it 'does not set a flash info message' do
        expect(flash[:info]).to be_nil
      end
    end

    context 'when the accessioning of samples fails' do
      # no tags provided for samples, when managed study tags are expected
      let(:samples) { create_list(:sample, number_of_samples) }
      let(:study) { create(:managed_study, accession_number: 'EGA123', samples: samples) }

      it 'redirects to the accession-statuses tab of the study page' do
        expect(subject).to redirect_to(study_path(study, anchor: 'accession-statuses'))
      end

      it 'does not set a flash notice message' do
        expect(flash[:notice]).to be_nil
      end

      it 'sets a flash error message' do
        # rubocop:disable Layout/LineLength
        expect(flash[:error]).to eq(
          [
            'The samples in this study could not be accessioned, please check the following errors:',
            "Sample 'Sample1' cannot be accessioned: Sample does not have the required metadata: donor-id, gender, phenotype, sample-common-name, and sample-taxon-id.",
            "Sample 'Sample2' cannot be accessioned: Sample does not have the required metadata: donor-id, gender, phenotype, sample-common-name, and sample-taxon-id.",
            "Sample 'Sample3' cannot be accessioned: Sample does not have the required metadata: donor-id, gender, phenotype, sample-common-name, and sample-taxon-id.",
            "Sample 'Sample4' cannot be accessioned: Sample does not have the required metadata: donor-id, gender, phenotype, sample-common-name, and sample-taxon-id.",
            "Sample 'Sample5' cannot be accessioned: Sample does not have the required metadata: donor-id, gender, phenotype, sample-common-name, and sample-taxon-id."
          ]
        )
        # rubocop:enable Layout/LineLength
      end

      context 'when the study has many samples' do
        let(:number_of_samples) { 10 }

        it 'does not set a flash notice message' do
          expect(flash[:notice]).to be_nil
        end

        it 'sets a flash error message' do
          # rubocop:disable Layout/LineLength
          expect(flash[:error]).to eq(
            [
              'The samples in this study could not be accessioned, please check the following errors:',
              "Sample 'Sample1' cannot be accessioned: Sample does not have the required metadata: donor-id, gender, phenotype, sample-common-name, and sample-taxon-id.",
              "Sample 'Sample2' cannot be accessioned: Sample does not have the required metadata: donor-id, gender, phenotype, sample-common-name, and sample-taxon-id.",
              "Sample 'Sample3' cannot be accessioned: Sample does not have the required metadata: donor-id, gender, phenotype, sample-common-name, and sample-taxon-id.",
              "Sample 'Sample4' cannot be accessioned: Sample does not have the required metadata: donor-id, gender, phenotype, sample-common-name, and sample-taxon-id.",
              "Sample 'Sample5' cannot be accessioned: Sample does not have the required metadata: donor-id, gender, phenotype, sample-common-name, and sample-taxon-id.",
              "Sample 'Sample6' cannot be accessioned: Sample does not have the required metadata: donor-id, gender, phenotype, sample-common-name, and sample-taxon-id.",
              '...',
              'Only the first 6 of 10 errors are shown.'
            ]
          )
          # rubocop:enable Layout/LineLength
        end

        it 'shows the error messages in the accession statuses of the samples' do
          study.samples.each do |sample|
            sample_status = Accession::SampleStatus.where(sample:).first
            expect(sample_status).to have_attributes(
              status: 'failed',
              message: "Sample '#{sample.name}' cannot be accessioned: " \
                       'Sample does not have the required metadata: ' \
                       'donor-id, gender, phenotype, sample-common-name, and sample-taxon-id.'
            )
          end
        end
      end

      context 'when samples are part of two accessionable studies' do
        let(:samples) { create_list(:sample_for_accessioning_with_open_study, number_of_samples) }
        let(:study) { create(:managed_study, accession_number: 'EGA123', samples: samples) }

        it 'redirects to the accession-statuses tab of the study page' do
          expect(subject).to redirect_to(study_path(study, anchor: 'accession-statuses'))
        end

        it 'does not set a flash notice message' do
          expect(flash[:notice]).to eq('All of the samples in this study have been sent for accessioning.')
        end

        it 'sets a flash error message' do
          expect(flash[:error]).to be_nil
        end

        it 'shows the logs' do
          samples.each do |sample|
            expect(Rails.logger).to have_received(:info)
              .with("Sample '#{sample.name}' should not be accessioned as it belongs to 2 accessionable studies.")
          end
        end
      end
    end
  end
end
