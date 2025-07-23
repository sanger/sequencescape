# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StudiesController do
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

  describe '#accession_all_samples', :accessioning_enabled do
    let(:samples) { create_list(:sample_for_accessioning_with_open_study, 5) }
    let(:study) { create(:open_study, accession_number: 'ENA123', samples: samples) }

    before { post :accession_all_samples, params: { id: study.id } }

    context 'when the accessioning succeeds' do
      it 'redirects to the study page' do
        expect(subject).to redirect_to(study_path(study))
      end

      it 'does not set a flash error message' do
        expect(flash[:error]).to be_nil
      end

      it 'sets a flash notice message' do
        expect(flash[:notice]).to eq('All of the samples in this study have been sent for accessioning.')
      end
    end

    context 'when the accessioning of samples fails' do
      let(:number_of_samples) { 5 }
      # tags provided for managed study, when open study is expected
      let(:samples) { create_list(:sample_for_accessioning_with_managed_study, number_of_samples) }

      it 'redirects to the study page' do
        expect(subject).to redirect_to(study_path(study))
      end

      it 'does not set a flash notice message' do
        expect(flash[:notice]).to be_nil
      end

      it 'sets a flash error message' do
        expect(flash[:error]).to eq(
          [
            'The samples in this study could not be accessioned, please check the following errors:',
            "Accessionable is invalid for sample 'Sample1': Sample has no appropriate studies.",
            "Accessionable is invalid for sample 'Sample2': Sample has no appropriate studies.",
            "Accessionable is invalid for sample 'Sample3': Sample has no appropriate studies.",
            "Accessionable is invalid for sample 'Sample4': Sample has no appropriate studies.",
            "Accessionable is invalid for sample 'Sample5': Sample has no appropriate studies."
          ]
        )
      end

      context 'when the study has many samples' do
        let(:number_of_samples) { 10 }

        it 'does not set a flash notice message' do
          expect(flash[:notice]).to be_nil
        end

        it 'sets a flash error message' do
          expect(flash[:error]).to eq(
            [
              'The samples in this study could not be accessioned, please check the following errors:',
              "Accessionable is invalid for sample 'Sample1': Sample has no appropriate studies.",
              "Accessionable is invalid for sample 'Sample2': Sample has no appropriate studies.",
              "Accessionable is invalid for sample 'Sample3': Sample has no appropriate studies.",
              "Accessionable is invalid for sample 'Sample4': Sample has no appropriate studies.",
              "Accessionable is invalid for sample 'Sample5': Sample has no appropriate studies.",
              "Accessionable is invalid for sample 'Sample6': Sample has no appropriate studies.",
              '...',
              'Only the first 6 of 10 errors are shown.'
            ]
          )
        end
      end
    end
  end
end
